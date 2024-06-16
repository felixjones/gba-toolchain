#===============================================================================
#
# ugba project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(16-ugba-project LANGUAGES C VERSION 1.0.0)

if(GBA)
    find_package(librom REQUIRED)
    find_package(ugba REQUIRED)
else()
    include(FetchContent)
    FetchContent_Declare(ugba
            GIT_REPOSITORY "https://github.com/AntonioND/libugba.git"
            GIT_TAG "master"
    )
    FetchContent_MakeAvailable(ugba)
endif()

add_executable(16-ugba
        main.c
)

target_link_libraries(16-ugba PRIVATE $<$<BOOL:${GBA}>:librom> ugba)

if(GBA)
    install_rom(16-ugba)
endif()
