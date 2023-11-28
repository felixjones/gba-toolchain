#===============================================================================
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include(FetchContent)

if(EXISTS "${CMAKE_SYSTEM_LIBRARY_PATH}/xilefianlib/CMakeLists.txt" OR EXISTS "${CMAKE_BINARY_DIR}/lib/xilefianlib/CMakeLists.txt")
    add_subdirectory("${CMAKE_SYSTEM_LIBRARY_PATH}/xilefianlib" "${CMAKE_BINARY_DIR}/lib/xilefianlib" EXCLUDE_FROM_ALL)
else()
    FetchContent_Declare(xilefianlib DOWNLOAD_EXTRACT_TIMESTAMP ON
        SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/xilefianlib"
        GIT_REPOSITORY "https://github.com/felixjones/xilefianlib.git"
        GIT_TAG "main"
    )

    FetchContent_MakeAvailable(xilefianlib)
endif()
