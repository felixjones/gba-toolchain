include(FetchContent)

if(EXISTS "${CMAKE_SYSTEM_LIBRARY_PATH}/gba-hpp/CMakeLists.txt" OR EXISTS "${CMAKE_BINARY_DIR}/lib/gba-hpp/CMakeLists.txt")
    add_subdirectory("${CMAKE_SYSTEM_LIBRARY_PATH}/gba-hpp" "${CMAKE_BINARY_DIR}/lib/gba-hpp" EXCLUDE_FROM_ALL)
else()
    FetchContent_Declare(gba-hpp DOWNLOAD_EXTRACT_TIMESTAMP ON
        SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/gba-hpp"
        GIT_REPOSITORY "https://github.com/felixjones/gba-hpp.git"
        GIT_TAG "dev"
    )

    FetchContent_MakeAvailable(gba-hpp)
endif()
