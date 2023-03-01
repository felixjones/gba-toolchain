include(ExternalProject)

find_library(libgbfs gbfs PATHS "$ENV{DEVKITPRO}/gbfs/lib" "${CMAKE_SYSTEM_LIBRARY_PATH}/gbfs/lib" "${GBFS_DIR}")

if(NOT libgbfs)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/gbfs")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/include")
    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    file(WRITE "${SOURCE_DIR}/temp/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(gbfs C)

        add_library(gbfs STATIC "libgbfs.c")

        install(TARGETS gbfs
            LIBRARY DESTINATION lib
        )
        install(FILES "gbfs.h"
            DESTINATION include
        )
    ]=])

    ExternalProject_Add(gbfs_proj DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        URL "http://pineight.com/gba/gbfs.zip"
        URL_MD5 "8cb0dd8e1ff0405071e2a0c58c0f76e2"
        # Update
        UPDATE_COMMAND "${CMAKE_COMMAND}" -E copy
            "${SOURCE_DIR}/temp/CMakeLists.txt"
            "${SOURCE_DIR}/source/CMakeLists.txt"
        # Configure
        SOURCE_DIR "${SOURCE_DIR}/source"
        CMAKE_ARGS --toolchain "${CMAKE_TOOLCHAIN_FILE}"
            -DCMAKE_INSTALL_PREFIX:PATH='${SOURCE_DIR}'
        # Build
        BINARY_DIR "${SOURCE_DIR}/build"
        BUILD_COMMAND "${CMAKE_COMMAND}" --build .
        BUILD_BYPRODUCTS "${SOURCE_DIR}/build/libgbfs.a"
        # Install
        INSTALL_DIR "${SOURCE_DIR}"
    )

    add_library(gbfs STATIC IMPORTED)
    add_dependencies(gbfs gbfs_proj)
    set_property(TARGET gbfs PROPERTY IMPORTED_LOCATION "${SOURCE_DIR}/build/libgbfs.a")
    target_include_directories(gbfs INTERFACE "${SOURCE_DIR}/include")
else()
    add_library(gbfs STATIC IMPORTED)
    set_property(TARGET gbfs PROPERTY IMPORTED_LOCATION "${libgbfs}")

    get_filename_component(INCLUDE_PATH "${libgbfs}" DIRECTORY)
    get_filename_component(INCLUDE_PATH "${INCLUDE_PATH}" DIRECTORY)
    target_include_directories(gbfs INTERFACE "${INCLUDE_PATH}/include")
endif()

unset(libgbfs CACHE)

include(FetchContent)

find_program(GBFS_PROGRAM gbfs PATHS "$ENV{DEVKITPRO}/tools/bin" "${CMAKE_SYSTEM_LIBRARY_PATH}/gbfs/bin" "${GBFS_DIR}")

if(NOT GBFS_PROGRAM)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/gbfs")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/include")
    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    file(WRITE "${SOURCE_DIR}/temp/ToolsCMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(gbfs C)

        add_executable(gbfs_tool "gbfs.c")
        set_target_properties(gbfs_tool PROPERTIES OUTPUT_NAME "gbfs")

        if(CMAKE_GENERATOR MATCHES "Visual Studio")
            target_sources(gbfs_tool PRIVATE "djbasename.c")
        endif()

        install(TARGETS gbfs_tool DESTINATION bin)
    ]=])

    FetchContent_Declare(gbfs_bin DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        # Download
        URL "http://pineight.com/gba/gbfs.zip"
        URL_HASH MD5=8cb0dd8e1ff0405071e2a0c58c0f76e2
        # Update
        UPDATE_COMMAND "${CMAKE_COMMAND}" -E copy
            "${SOURCE_DIR}/temp/ToolsCMakeLists.txt"
            "${SOURCE_DIR}/source/tools/CMakeLists.txt"
        # Configure
        SOURCE_DIR "${SOURCE_DIR}/source"
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX:PATH='${SOURCE_DIR}'
        # Build
        BINARY_DIR "${SOURCE_DIR}/build/tools"
        BUILD_COMMAND "${CMAKE_COMMAND}" --build .
        # Install
        INSTALL_DIR "${SOURCE_DIR}/bin"
    )

    FetchContent_GetProperties(gbfs_bin)
    if(NOT gbfs_bin_POPULATED)
        FetchContent_Populate(gbfs_bin)

        # Configure
        execute_process(
            COMMAND ${CMAKE_COMMAND} -S . -B "${SOURCE_DIR}/build/tools"
            WORKING_DIRECTORY "${SOURCE_DIR}/source/tools"
            RESULT_VARIABLE cmakeResult
        )

        # Build
        execute_process(
            COMMAND ${CMAKE_COMMAND} --build . --config Release
            WORKING_DIRECTORY "${SOURCE_DIR}/build/tools"
            RESULT_VARIABLE cmakeResult
        )

        # Install
        execute_process(
            COMMAND ${CMAKE_COMMAND} --install . --prefix "${SOURCE_DIR}" --config Release
            WORKING_DIRECTORY "${SOURCE_DIR}/build/tools"
            RESULT_VARIABLE cmakeResult
        )
    endif()
endif()

# TODO: `add_gbfs` function for GBFS generated sources (or binary)
