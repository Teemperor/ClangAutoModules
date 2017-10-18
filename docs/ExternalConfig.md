# Using it externally to a project

ClangAutoModules can modularize a CMake project during compilation without
modifying the project itself. This works by injecting a custom clang wrapper
called `clang_modules` via your CC/CXX variables to CMake during configuration.

CMake then calls this wrapper to compile each translation unit, which will in
turn sets up the system modules and afterwards just calls clang to compile
the translation unit. If clang wouldn't use modules to compile this
translation unit, the wrapper also adds arguments to activate modules in clang.

## Limitations

This script only work with CMake project at the moment as we generate some
temporary files that end up the build directory specified by CMake. If the
script is used outside of a CMake project, the script just forward the
invocation unchanged to clang.

The script caches the generated modules setup and only reconfigures another
modules setup in certain situations (e.g. language standards change).

## How to use

In general the only change you need to do is prefix the `cmake` command
you use to configure your build directory with `CC=path/to/clang_modules CXX=path/to/clang_modules++`.

The final invocation looks like:

``bash
CC=path/to/clang_modules CXX=path/to/clang_modules++ cmake ..
```

(For other shells that are not compatible with this syntax you might need
to use another syntax for setting these environment variables).
