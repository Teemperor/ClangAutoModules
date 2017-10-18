# Using it in your CMake script

ClangAutoModules comes with a standalone CMake script that wraps
all necessary code and files for setting up system modules. As it's standalone,
it can just be downloaded via CMake and then directly executed by `include`ing
it in the CMakeLists.txt.

```CMake
file(DOWNLOAD "https://github.com/Teemperor/ClangAutoModules/releases/download/0.2/ClangModules.cmake"
     "${CMAKE_BINARY_DIR}/ClangModules.cmake"
     EXPECTED_HASH SHA256=1a905f62fc9c31ea62f67e70f0e9f17442f9e3c36b4757adc4e3d71d9a39314e)

include(${CMAKE_BINARY_DIR}/ClangModules.cmake)
```

## How it works.

The included script queries the current configured include directories of this
CMake project and then starts looking for modules in those paths. This also
means that the script should be called at a point where all relevant system
include paths have been set up.

## Extra parameters

There are a few parameters to configure the script.

* `ClangModules_CheckOnlyFor` (list) : List of modules that the script only
   should check for. Any modules not listed here will not be checked. Useful
   for making the script faster during configuration.

* `ClangModules_CustomModulemapFolders` (list) : List of folders that contain
   additional [modulemaps](Modulemaps.md) that ClangAutoModules should try to
   mount in the system. Default is an empty list.

* `ClangModules_RequiredModules` (list) : List of module names that are required
   to be successfully located for the script to succeed. Useful if you have a
   modules regression build and want to be warned if some library actually
   becomes incompatible with clang. Default is an empty list.

* `ClangModules_OutputVFSFile` (string) : Path to where ClangAutoModules should
   write the VFS file.

* `ClangModules_ModulesCache` (string) : Path to where the custom modules
   cache should be generated. Default value is the `pcm` directory in the
   `CMAKE_BINARY_DIR`.

* `ClangModules_WithoutClang` (bool) : Whether to use clang to check if modules
  are usable to compile. Turning this to ON makes the configuration much faster
  but also very imprecise. Default is OFF.
