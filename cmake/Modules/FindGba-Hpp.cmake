include(FetchContent)

if(EXISTS "${CMAKE_SYSTEM_LIBRARY_PATH}/gba-hpp/CMakeLists.txt" OR EXISTS "${CMAKE_BINARY_DIR}/lib/gba-hpp/CMakeLists.txt")
    add_subdirectory("${CMAKE_SYSTEM_LIBRARY_PATH}/gba-hpp" "${CMAKE_BINARY_DIR}/lib/gba-hpp" EXCLUDE_FROM_ALL)
endif()

if(NOT gba-hpp)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/gba-hpp")

    FetchContent_Declare(gba-hpp_proj DOWNLOAD_EXTRACT_TIMESTAMP ON
        SOURCE_DIR "${SOURCE_DIR}"
        GIT_REPOSITORY "https://github.com/felixjones/gba-hpp.git"
        GIT_TAG "main"
    )

    FetchContent_MakeAvailable(gba-hpp_proj)
endif()
