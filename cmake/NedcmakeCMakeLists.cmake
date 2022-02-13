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

# Fixup nedcmake.cpp
file(READ "src/nedcmake.cpp" filedata)
string(REGEX REPLACE "fclose[(]f[)];" "if(f)fclose(f);f=NULL;" filedata "${filedata}")
string(REGEX REPLACE "fwrite[(]carddata,1,cardsize,f[)];" "if(f)fwrite(carddata,1,cardsize,f);" filedata "${filedata}")
file(WRITE "src/nedcmake.cpp" "${filedata}")

# nedclib shared library
file(GLOB_RECURSE nedclibSrc "src/lib/*.cpp")

# Fixup malloc.h in all sources
foreach(source ${nedclibSrc})
    file(READ "${source}" filedata)
    string(REGEX REPLACE "#include <malloc[.]h>" "#include <stdlib.h>" filedata "${filedata}")
    file(WRITE "${source}" "${filedata}")
endforeach()

# Detect MSYS
execute_process(COMMAND uname OUTPUT_VARIABLE uname)
if (uname MATCHES "^MSYS" OR uname MATCHES "^MINGW")
    set(MSYS ON)
endif()

if(WIN32 OR MSYS)
    set(libraryType SHARED)
else()
    set(libraryType STATIC)
endif()

add_library(nedclib ${libraryType} ${nedclibSrc})
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

if(WIN32 OR MSYS)
    install(TARGETS nedclib DESTINATION .)
endif()
install(TARGETS nedcmake DESTINATION .)
