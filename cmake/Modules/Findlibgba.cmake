#===============================================================================
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

if(TARGET libgba)
    return()
endif()

find_library(LIBGBA_PATH gba
        PATHS ${devkitARM} "${LIBGBA_DIR}"
        PATH_SUFFIXES "lib" "libgba/lib"
)

if(LIBGBA_PATH)
    add_library(libgba STATIC IMPORTED)
    set_property(TARGET libgba PROPERTY IMPORTED_LOCATION "${LIBGBA_PATH}")

    get_filename_component(gbaPath "${LIBGBA_PATH}" DIRECTORY)
    get_filename_component(gbaPath "${gbaPath}" DIRECTORY)
    if(EXISTS "${gbaPath}/include/gba.h")
        target_include_directories(libgba INTERFACE "${gbaPath}/include")
    endif()

    if(NOT DEVKITPRO)
        add_subdirectory("${CMAKE_SYSTEM_PREFIX_PATH}/lib/iosupport" "${CMAKE_CURRENT_BINARY_DIR}/lib/iosupport" EXCLUDE_FROM_ALL)

        target_link_libraries(libgba INTERFACE iosupport)
    endif()

    return()
endif()

include(FetchContent)
include(Mktemp)

add_subdirectory("${CMAKE_SYSTEM_PREFIX_PATH}/lib/iosupport" "${CMAKE_CURRENT_BINARY_DIR}/lib/iosupport" EXCLUDE_FROM_ALL)

mktemp(libgbaCMakeLists TMPDIR)
file(WRITE "${libgbaCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(libgba ASM C)

add_subdirectory("${CMAKE_SYSTEM_PREFIX_PATH}/lib/iosupport" "${CMAKE_CURRENT_BINARY_DIR}/lib/iosupport" EXCLUDE_FROM_ALL)

file(GLOB_RECURSE sources CONFIGURE_DEPENDS "src/*.s" "src/*.c")

add_library(libgba STATIC ${sources})
set_target_properties(libgba PROPERTIES PREFIX "")
target_include_directories(libgba SYSTEM PUBLIC include)

target_compile_options(libgba PRIVATE
    $<$<COMPILE_LANGUAGE:ASM>:-x assembler-with-cpp>
)

set_source_files_properties("src/console.c" PROPERTIES COMPILE_FLAGS -Wno-incompatible-pointer-types)
set_source_files_properties("src/xcomms.c" "src/xcomms_print.c" PROPERTIES COMPILE_FLAGS -Wno-multichar)
set_source_files_properties("src/fade.c" PROPERTIES COMPILE_FLAGS -Wno-discarded-qualifiers)

add_asset_library(amiga_fnt SUFFIX_SIZE _size "data/amiga.fnt")

target_link_libraries(libgba PRIVATE iosupport amiga_fnt)
]=])

FetchContent_Declare(libgba
        GIT_REPOSITORY "https://github.com/devkitPro/libgba.git"
        GIT_TAG "master"
        PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${libgbaCMakeLists}" "CMakeLists.txt"
)
FetchContent_MakeAvailable(libgba)

file(REMOVE "${libgbaCMakeLists}")
