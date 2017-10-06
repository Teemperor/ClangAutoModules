#!/usr/bin/env python

import sys
from shutil import copyfile
import subprocess
from subprocess import check_output
from subprocess import call
import os
import re

exit_code = 0
exit_code += call(["rm", "-rf", sys.argv[3]])
exit_code += call(["cp", "-r", sys.argv[2], sys.argv[3]])
copyfile(sys.argv[1] + "/ClangModules.cmake",
         sys.argv[3] + "/ClangModules.cmake")
os.chdir(sys.argv[3])
exit_code += call(["mkdir", "build"])
os.chdir("build")
output = check_output(["cmake", ".."], stderr=subprocess.STDOUT)
exit_code += call(["make"])


out_encoding = sys.stdout.encoding
if out_encoding is None:
    out_encoding = 'utf-8'

output = output.decode(out_encoding).splitlines()

if exit_code != 0:
    print("One of the commands had non-zero exit code!")
    exit(1)

in_modules_output = False
modules_output = []

if os.path.isfile("HasClang"):
    for line in output:
        if "Done setting up ClangModules!" in line:
            in_modules_output = False
        if in_modules_output:
            modules_output.append(line)
        if "Setting up ClangModules:" in line:
            in_modules_output = True

    if in_modules_output:
        exit("Couldn't find end of modules output! " + str(modules_output))

    ok_pat = re.compile(r"^   Module \S+ +->   OK! \S+$")
    fail_pat = re.compile(r"^   Module \S+ +-> FAIL!$")
    for o in modules_output:
        if ok_pat.match(o):
            pass
        elif fail_pat.match(o):
            pass
        else:
            exit("Couldn't recognize output '" + str(o) + "'")

    if len(modules_output) == 0:
        exit("Empty modules output!" + str(output))
