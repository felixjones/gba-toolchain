#===============================================================================
#
# agbabi support library for GBA
# Includes GBA optimised aeabi implementations and support functions
#   https://github.com/felixjones/agbabi
#
# Linking with agbabi will enable optimised memcpy and div
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include(FetchContent)

FetchContent_Declare(agbabi
        GIT_REPOSITORY "https://github.com/felixjones/agbabi.git"
        GIT_TAG "main"
        EXCLUDE_FROM_ALL
)

FetchContent_MakeAvailable(agbabi)
