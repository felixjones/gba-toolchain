#===============================================================================
#
# CMakeLists.txt for compiling nedcmake
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.0)

project(nedcmake CXX)

# Fixup dcs.h
file(READ "src/lib/rawbmp/dcs.h" filedata)
string(REGEX REPLACE "extern int dpi_multiplier;" "//extern int dpi_multiplier;" filedata "${filedata}")
file(WRITE "src/lib/rawbmp/dcs.h" "${filedata}")

# nedclib shared library
file(GLOB_RECURSE nedclibSrc "src/lib/*.cpp")
add_library(nedclib SHARED ${nedclibSrc})
target_compile_definitions(nedclib PRIVATE NEDCLIB2_EXPORTS)
target_include_directories(nedclib PRIVATE src/lib src/lib/rawbmp)

# nedcmake executable
add_executable(nedcmake src/nedcmake.cpp)
target_include_directories(nedcmake PRIVATE src/lib)
if(CMAKE_GENERATOR MATCHES "Visual Studio")
    target_compile_definitions(nedcmake PRIVATE strcasecmp=_stricmp) # This is a POSIX specific API
endif()
add_dependencies(nedcmake nedclib)
target_link_libraries(nedcmake PRIVATE nedclib)

# C++11
set_target_properties(nedclib nedcmake
    PROPERTIES CXX_STANDARD 11
)

install(TARGETS nedclib DESTINATION .)
install(TARGETS nedcmake DESTINATION .)
