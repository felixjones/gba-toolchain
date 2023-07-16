include(Compiler/CMakeCommonCompilerMacros)
include(${CMAKE_ROOT}/Modules/CMakeDetermineCompileFeatures.cmake)
cmake_determine_compile_features(CXX)

set(CMAKE_CXX_FLAGS_RELEASE_INIT        "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG_INIT          "-O0 -g -D_DEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT "-Og -g -DNDEBUG")
set(CMAKE_CXX_FLAGS_MINSIZEREL_INIT     "-Os -DNDEBUG")
