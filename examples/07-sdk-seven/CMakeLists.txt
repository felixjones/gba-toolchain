#===============================================================================
#
# sdk-seven project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(07-sdk-seven-project LANGUAGES C VERSION 1.0.0)

find_package(sdk-seven REQUIRED
        COMPONENTS runtime libseven libutil
)

add_executable(07-sdk-seven
        main.c
)

target_link_libraries(07-sdk-seven PRIVATE
        sdk-seven::minrt sdk-seven::libseven sdk-seven::libutil
)

add_gbafix_target(07-sdk-seven-fixed 07-sdk-seven)
