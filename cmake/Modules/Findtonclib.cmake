#===============================================================================
#
# Adds the `tonclib` package and library.
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

if(TARGET tonclib)
    return()
endif()

find_library(LIBTONC_PATH tonc
        PATHS ${devkitARM} "${TONCLIB_DIR}"
        PATH_SUFFIXES "lib" "libtonc/lib"
)

if(LIBTONC_PATH)
    add_library(tonclib STATIC IMPORTED)
    set_property(TARGET tonclib PROPERTY IMPORTED_LOCATION "${LIBTONC_PATH}")

    get_filename_component(toncPath "${LIBTONC_PATH}" DIRECTORY)
    get_filename_component(toncPath "${toncPath}" DIRECTORY)
    if(EXISTS "${toncPath}/include/tonc.h")
        target_include_directories(tonclib INTERFACE "${toncPath}/include")
    endif()

    return()
endif()

include(FetchContent)
include(Mktemp)

mktemp(toncCMakeLists TMPDIR)
file(WRITE "${toncCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(libtonc ASM C)

add_subdirectory("${CMAKE_SYSTEM_PREFIX_PATH}/lib/iosupport" "${CMAKE_CURRENT_BINARY_DIR}/lib/iosupport" EXCLUDE_FROM_ALL)

file(GLOB_RECURSE sources CONFIGURE_DEPENDS "asm/*.s" "src/*.s" "src/*.c")

add_library(tonclib STATIC ${sources})
set_target_properties(tonclib PROPERTIES PREFIX "")
target_include_directories(tonclib SYSTEM PUBLIC include)

target_compile_options(tonclib PRIVATE
    $<$<COMPILE_LANGUAGE:ASM>:-x assembler-with-cpp>
    $<$<COMPILE_LANGUAGE:C>:-mthumb -O2>
)

set_source_files_properties("src/tte/tte_iohook.c" PROPERTIES COMPILE_FLAGS "-Wno-incompatible-pointer-types -Wno-stringop-overflow")

target_link_libraries(tonclib PRIVATE iosupport)
]=])

FetchContent_Declare(tonclib
        GIT_REPOSITORY "https://github.com/devkitPro/libtonc.git"
        GIT_TAG "master"
        PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${toncCMakeLists}" "CMakeLists.txt"
)
FetchContent_MakeAvailable(tonclib)

file(REMOVE "${toncCMakeLists}")
