#===============================================================================
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include(FetchContent)

FetchContent_Declare(gba-hpp
        GIT_REPOSITORY "https://github.com/felixjones/gba-hpp.git"
        GIT_TAG "main"
)

FetchContent_GetProperties(gba-hpp)
if(NOT gba-hpp_POPULATED)
    FetchContent_Populate(gba-hpp)
    add_subdirectory(${gba-hpp_SOURCE_DIR} ${gba-hpp_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()
