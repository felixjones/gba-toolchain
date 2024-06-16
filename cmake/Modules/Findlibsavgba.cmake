#===============================================================================
#
# Media backup library
#   GitHub: https://github.com/laqieer/libsavgba
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include(FetchContent)
include(Mktemp)

mktemp(libsavgbaCMakeLists TMPDIR)
file(WRITE "${libsavgbaCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(libsavgba C)

find_package(tonclib REQUIRED)

add_subdirectory("${CMAKE_SYSTEM_PREFIX_PATH}/lib/iosupport" "${CMAKE_CURRENT_BINARY_DIR}/lib/iosupport" EXCLUDE_FROM_ALL)

file(GLOB sources CONFIGURE_DEPENDS "src/*.c")

add_library(libsavgba STATIC ${sources})
set_target_properties(libsavgba PROPERTIES PREFIX "")
target_include_directories(libsavgba PUBLIC include/)
target_link_libraries(libsavgba
    PRIVATE tonclib iosupport
)
]=])

FetchContent_Declare(libsavgba
        GIT_REPOSITORY "https://github.com/aronson/libsavgba.git"
        GIT_TAG "main"
        PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${libsavgbaCMakeLists}" "CMakeLists.txt"
)
FetchContent_MakeAvailable(libsavgba)

file(REMOVE "${libsavgbaCMakeLists}")
