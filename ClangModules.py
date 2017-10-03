#!/usr/bin/env python

import copy
import json
import subprocess
import re
import shutil
import sys
import os


def eprint(msg):
    sys.stderr.write(str(msg) + "\n")
    sys.stderr.flush()


class InvokResult:
    def __init__(self, output, exit_code):
        self.output = str(output)
        self.exit_code = exit_code


class ParseDepsResult:
    def __init__(self, after, error=False):
        self.after = after
        self.error = error

    def get_values(self):
        assert not self.error
        return self.after


def make_match_pattern(key):
    return re.compile("^[\s]*//[\s]*" + key + ":")


provides_line_pattern = make_match_pattern("provides")
after_line_pattern = make_match_pattern("after")


def parse_value_line(pattern, line):
    depends_on = []
    if pattern.match(line):
        parts = line.split(":")
        assert len(parts) >= 2
        after = parts[1]
        deps_parts = after.split()
        for dep in deps_parts:
            stripped = dep.strip()
            if " " in stripped:
                return ParseDepsResult(None, True)
            if "\t" in stripped:
                return ParseDepsResult(None, True)
            else:
                depends_on.append(stripped)
        return ParseDepsResult(depends_on)
    else:
        return ParseDepsResult(None, True)


assert parse_value_line(after_line_pattern, "// after").error
assert parse_value_line(after_line_pattern, "/d/ after").error
assert parse_value_line(after_line_pattern, "d// after:").error
assert parse_value_line(
    after_line_pattern, "// after: bla").get_values() == ["bla"]
assert parse_value_line(
    after_line_pattern, " // after: bla").get_values() == ["bla"]
assert parse_value_line(
    after_line_pattern, "//  after: bla").get_values() == ["bla"]
assert parse_value_line(
    after_line_pattern, "//  after: c++").get_values() == ["c++"]
assert parse_value_line(
    after_line_pattern, "//  after: c++17").get_values() == ["c++17"]
assert parse_value_line(
    after_line_pattern, "// after: bla foo").get_values() == ["bla", "foo"]
assert parse_value_line(
    after_line_pattern, "// after: bla  foo").get_values() == ["bla", "foo"]
assert parse_value_line(
    after_line_pattern, "// after: bla \t foo").get_values() == ["bla", "foo"]


class MultipleProvidesError(Exception):
    pass


class NotOneProvideError(Exception):
    pass


class Modulemap:
    def __init__(self, mm_file):
        self.mm_file = mm_file
        self.depends_on = []
        self.provides = None
        self.headers = []
        with open(mm_file, "r") as f:
            for line in f:

                rematch = re.search(r"header\s+\"([^\"]+)\"", line)
                if rematch:
                    self.headers.append(rematch.group(1))

                new_deps = parse_value_line(after_line_pattern, line)
                if not new_deps.error:
                    self.depends_on = self.depends_on + new_deps.get_values()
                new_provides = parse_value_line(provides_line_pattern, line)
                if not new_provides.error:
                    if self.provides is not None:
                        raise MultipleProvidesError()
                    if len(new_provides.get_values()) != 1:
                        raise NotOneProvideError()
                    self.provides = new_provides.get_values()[0]
        file_name = os.path.basename(mm_file)
        self.name = os.path.splitext(file_name)[0]

    def can_use_in_dir(self, path):
        for header in self.headers:
            if not os.path.isfile(os.path.sep.join([path, header])):
                eprint("  Missing " + header)
                return False
        return True

    def matches(self, name):
        if self.name == name:
            return True
        if self.provides and self.provides == name:
            return True
        return False

    def __repr__(self):
        return self.name + ".modulemap"


class ModulemapGraph:
    def __init__(self, modulemaps):
        self.modulemaps = modulemaps
        self.modulemaps.sort(key=lambda x: x.name)
        self.handled = {}
        self.success = {}
        self.providers = {}
        for mm in self.modulemaps:
            self.handled[mm.name] = False
            self.success[mm.name] = False
            if mm.provides:
                if mm.provides in self.providers:
                    self.providers[mm.provides].append(mm)
                else:
                    self.providers[mm.provides] = [mm]

        for mm in self.modulemaps:
            assert mm.name not in self.providers, \
                "modulemap name shared name with provided: %s" % mm.name

    def is_provided(self, prov):
        assert prov in self.providers, "Unknown prov %s " % prov
        for p in self.providers[prov]:
            if self.success[p.name]:
                return True
        for p in self.providers[prov]:
            if not self.handled[p.name]:
                return False
        return True

    def requirement_success(self, req):
        if req in self.success:
            return self.success[req]
        assert req in self.providers, "Unknown req %s " % req
        for p in self.providers[req]:
            if self.success[p.name]:
                return True
        return False

    def requirement_done(self, req):
        if req in self.handled:
            return self.handled[req]
        return self.is_provided(req)

    def can_test_modulemap(self, mm):
        if self.handled[mm.name]:
            return False
        if mm.provides:
            if self.is_provided(mm.provides):
                return False
        for dep in mm.depends_on:
            if not self.requirement_done(dep):
                return False
        return True

    def mark_modulemap(self, mm, success):
        self.handled[mm.name] = True
        self.success[mm.name] = success

    def get_next_modulemap(self):
        for mm in self.modulemaps:
            if self.can_test_modulemap(mm):
                return mm
        return None


class FileBak:
    def __init__(self, path):
        self.path = path
        try:
            with open(self.path, 'r') as f:
                self.data = f.read()
        except EnvironmentError:
            self.data = None

    def revert(self):
        if self.data is None:
            os.remove(self.path)
        else:
            with open(self.path, 'w') as f:
                f.write(self.data)


class VirtualFileSystem:
    def __init__(self, yaml_file, cache_path):
        self.yaml_file = yaml_file
        self.yaml = {'version': 0, 'roots': []}
        self.roots = self.yaml["roots"]
        self.file_bak = None
        self.cache_path = cache_path
        self.update_yaml()

    def has_target_path(self, target_path):
        for root in self.roots:
            if root["name"] == target_path:
                return True
        return False

    def backup(self, path):
        self.yaml_bak = copy.deepcopy(self.yaml)
        self.file_bak = FileBak(path)

    def revert(self):
        self.yaml = self.yaml_bak
        self.roots = self.yaml["roots"]
        self.file_bak.revert()

    def update_yaml(self):
        with open(self.yaml_file, 'w') as fp:
            json.dump(self.yaml, fp, sort_keys=False, indent=2)

    def make_cache_file(self, target_path):
        target_path = os.path.abspath(target_path)
        target_path = target_path.replace("/", "_").replace(".", "_")
        return os.path.abspath(os.path.join(self.cache_path, target_path))

    def append_file(self, source, target, append):
        open_mode = "w"
        if append:
            open_mode = "a"
        with open(target, open_mode) as target_file:
            with open(source, "r") as source_file:
                target_file.write(source_file.read())

    def mount_file(self, source_file, target_dir,
                   file_name='module.modulemap'):
        cache_file = self.make_cache_file(target_dir)
        if not self.has_target_path(target_dir):
            try:
                os.remove(cache_file)
            except EnvironmentError:
                pass
        self.backup(cache_file)
        self.append_file(source_file, cache_file,
                         self.has_target_path(target_dir))
        if not self.has_target_path(target_dir):
            new_entry = {}
            new_entry["name"] = str(target_dir)
            new_entry["type"] = "directory"
            new_entry["contents"] = [
                {'name': file_name, 'type': 'file',
                 'external-contents': str(cache_file)}]
            self.roots.append(new_entry)
            self.update_yaml()


class ClangModules:
    def __init__(self, clang_invok, clangless_mode, modulemap_dirs,
                 extra_inc_dirs, check_only):
        inc_args = ""
        for inc_dir in extra_inc_dirs:
            inc_args += " -I \"" + inc_dir + "\" "
        self.clang_invok = clang_invok + inc_args
        self.clangless_mode = clangless_mode
        self.check_only = check_only
        self.include_paths = self.calculate_include_paths()
        self.modulemap_dirs = modulemap_dirs
        self.mm_graph = None
        self.pcm_tmp_dir = pcm_tmp_dir
        self.parse_modulemaps()

    def invoke_clang(self, suffix, force_with_clangless=False):
        if self.clangless_mode and not force_with_clangless:
            return InvokResult("", 0)
        out_encoding = sys.stdout.encoding
        if out_encoding is None:
            out_encoding = 'utf-8'
        try:
            output = subprocess.check_output(
                "LANG=C " + self.clang_invok + " " + suffix,
                stderr=subprocess.STDOUT, shell=True)
            output = output.decode(out_encoding)
        except subprocess.CalledProcessError as exc:
            return InvokResult(exc.output.decode(out_encoding), 1)
        else:
            return InvokResult(output, 0)

    def requirement_success(self, prov):
        return self.mm_graph.requirement_success(prov)

    def get_next_modulemap(self):
        while True:
            mm = self.mm_graph.get_next_modulemap()

            if mm is None:
                return None

            if self.check_only:
                for c in self.check_only:
                    if mm.matches(c):
                        return mm
                m.mm_graph.mark_modulemap(mm, False)
                continue

            return mm

    def parse_modulemaps(self):
        modulemaps = []
        for modulemap_dir in self.modulemap_dirs:
            for filename in os.listdir(modulemap_dir):
                if not filename.endswith(".modulemap"):
                    continue
                file_path = os.path.abspath(
                    os.path.sep.join([modulemap_dir, filename]))
                mm = Modulemap(file_path)
                modulemaps.append(mm)
        self.mm_graph = ModulemapGraph(modulemaps)

    def calculate_include_paths(self, make_abs=True):
        includes = []
        output = self.invoke_clang("-xc++ -v -E /dev/null", True)
        # In clangless_mode we can fail when we have a non GCC compatible
        # compiler that doesn't like our invocation above.
        if output.exit_code != 0 and not self.clangless_mode:
            raise NameError(
                'Clang failed with non-zero exit code: ' + str(output.output))
        output = output.output
        in_includes = False
        for line in output.splitlines():
            if in_includes:
                if line.startswith(" "):
                    path = line.strip()
                    if make_abs:
                        path = os.path.abspath(path)

                    includes.append(path)
                else:
                    in_includes = False
            if '#include "..."' in line or '#include <...>' in line:
                in_includes = True
        return includes

    def create_test_file(self, mm, output):
        with open(output, "w") as f:
            for header in mm.headers:
                f.write("#include \"" + header + "\"\n")
            f.write("\nint main() {}\n")


def arg_parse_error(message):
    sys.stderr.write("Error: " + message + "\n")
    exit(3)


# Argument parsing
clang_invok = None
parsing_invocation = False
modulemap_dirs = []
check_only = None
required_modules = None
output_dir = None
parsed_arg = True
extra_inc_dirs = []
clangless_mode = False
vfs_output = None

for i in range(0, len(sys.argv)):
    if parsed_arg:
        parsed_arg = False
        continue
    arg = sys.argv[i]
    if i + 1 < len(sys.argv):
        next_arg = sys.argv[i + 1]
    else:
        next_arg = None

    if parsing_invocation:
        clang_invok += " " + arg + ""
    else:
        if arg == "--invocation":
            parsing_invocation = True
            clang_invok = ""
        elif arg == "--check-only":
            if not next_arg:
                arg_parse_error("No arg supplied for --check-only")
            if check_only is None:
                check_only = []
            check_only += filter(None, next_arg.split(";"))
            parsed_arg = True
        elif arg == "--required-modules":
            if not next_arg:
                arg_parse_error("No arg supplied for --required-modules")
            if required_modules is None:
                required_modules = []
            required_modules += filter(None, next_arg.split(";"))
            parsed_arg = True
        elif arg == "--clangless":
            clangless_mode = True
        elif arg == "--modulemap-dir":
            if not next_arg:
                arg_parse_error("No arg supplied for --modulemap-dir")
            for path in next_arg.split(";"):
                if len(path) > 0:
                    modulemap_dirs.append(path)
            parsed_arg = True
        elif arg == "--vfs-output":
            if not next_arg:
                arg_parse_error("No arg supplied for --vfs-output")
            if next_arg != "-":
                vfs_output = next_arg
            parsed_arg = True
        elif arg == "-I":
            if not next_arg:
                arg_parse_error("No arg supplied for -I")
            for path in next_arg.split(":"):
                if len(path) > 0:
                    extra_inc_dirs.append(path)
            parsed_arg = True
        elif arg == "--output-dir":
            if not next_arg:
                arg_parse_error("No arg supplied for --output-dir")
            if output_dir:
                arg_parse_error(
                    "specified multiple output dirs with --output-dir")
            output_dir = next_arg
            parsed_arg = True
        else:
            arg_parse_error("Unknown arg: " + arg)

if len(modulemap_dirs) == 0:
    arg_parse_error("Not modulemap directories specified with --modulemap-dir")

if not output_dir:
    arg_parse_error("Not output_dir specified with --output-dir")

if not clang_invok:
    arg_parse_error("No clang invocation specified with --invocation [...]")

if not vfs_output:
    vfs_output = os.path.sep.join([output_dir, "ClangModulesVFS.yaml"])

vfs = VirtualFileSystem(vfs_output, output_dir)

pcm_tmp_dir = os.path.sep.join([output_dir, "ClangModulesPCMs"])

test_cpp_file = os.path.sep.join([output_dir, "ClangModules.cpp"])

m = ClangModules(clang_invok, clangless_mode,
                 modulemap_dirs, extra_inc_dirs, check_only)
# print(m.include_paths)

clang_flags = " -fmodules -fcxx-modules -Xclang " + \
    "-fmodules-local-submodule-visibility -ivfsoverlay \"" + vfs_output + "\" "

while True:
    mm = m.get_next_modulemap()
    if mm is None:
        break
    success = False
    eprint("Module  " + mm.name)
    for inc_path in m.include_paths:
        eprint(" Selecting " + inc_path)
        if not mm.can_use_in_dir(inc_path):
            continue
        eprint(" Checking " + inc_path)
        vfs.mount_file(mm.mm_file, inc_path)
        m.create_test_file(mm, test_cpp_file)
        shutil.rmtree(pcm_tmp_dir, True)
        invoke_result = m.invoke_clang("-fmodules-cache-path=" + pcm_tmp_dir +
                                       " -fsyntax-only -Rmodule-build " +
                                       clang_flags + test_cpp_file)
        # print(m.mm_graph.providers)
        success = (invoke_result.exit_code == 0)
        if success:
            eprint("works " + mm.name + " " + str(inc_path))
            break
        else:
            eprint("error:" + invoke_result.output)
            vfs.revert()
    m.mm_graph.mark_modulemap(mm, success)

if required_modules:
    for mod in required_modules:
        if not m.requirement_success(mod):
            eprint("Missing module " + mod)
            exit(2)

if not clangless_mode:
    print(clang_flags)
