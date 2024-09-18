#===============================================================================
#
# Some of my (Xilefian's) utility libraries
#   https://github.com/felixjones/xilefianlib
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include(FetchContent)

FetchContent_Declare(xilefianlib
        GIT_REPOSITORY "https://github.com/felixjones/xilefianlib.git"
        GIT_TAG "main"
        EXCLUDE_FROM_ALL
)

FetchContent_MakeAvailable(xilefianlib)
