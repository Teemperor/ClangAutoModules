# Modulemap files

ClangAutoTools uses clang modulemap files for configuring modules. The format
is specified in the [clang manual](https://clang.llvm.org/docs/Modules.html).

## Flags:

There are some extensions to this format wrapped inside comments that contain
ClangAutoModules specific variables.

### Flag: provides

Syntax: `// provides: VALUE`

Specifies that the given modulemap provides a certain
library. ClangAutoModules ensures that there is only have one modulemap with a
certain provides value. This allows to version for example to add versions to
modulemaps by having multiple modulemaps for a library in each version that
all provide the same value. E.g. all STL modulemaps have a `// provides: stl`
to make sure we only mount a single STL modulemap.

### Flag: after

Syntax: `// after: VALUE [, VALUE...]`

Specifies which libraries should be checked before checking the current
modulemap. In combination with `provides:` this can be used to specify
a chain of modulemap in decreasing version order to check library for.

The value is either a modulemap file name (without the `.modulemap` suffix)
or a value that one library has in its `provides:` value.

Examples: `// after: stl` to check this library after stl has been setup.

### Flag: needed_flags

Syntax: `// needed_flags: VALUE [, VALUE...]`

Only check the current modulemap if the current flags are set. This is only
useful for the `clangless` mode in which we can't let clang decide if the
modulemap is usable with the current configuration.
