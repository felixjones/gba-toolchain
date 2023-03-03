include(FetchContent)

find_library(libgbfs gbfs PATHS "$ENV{DEVKITPRO}/gbfs" "${CMAKE_SYSTEM_LIBRARY_PATH}/gbfs" "${GBFS_DIR}" PATH_SUFFIXES lib)
find_program(CMAKE_GBFS_PROGRAM gbfs PATHS "$ENV{DEVKITPRO}/tools" "${CMAKE_SYSTEM_LIBRARY_PATH}/gbfs" "${GBFS_DIR}" PATH_SUFFIXES bin)

if(NOT libgbfs OR NOT CMAKE_GBFS_PROGRAM)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/gbfs")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    file(WRITE "${SOURCE_DIR}/temp/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(gbfs C)

        if(CMAKE_SYSTEM_NAME STREQUAL AdvancedGameBoy)
            add_library(gbfs STATIC "libgbfs.c")

            target_compile_options(gbfs PRIVATE
                $<$<COMPILE_LANGUAGE:C>: -mthumb
                    -fomit-frame-pointer
                    -ffunction-sections
                    -fdata-sections
                    -Wall
                    -Wextra
                    -Wpedantic
                    -Wconversion
                    -Wno-sign-conversion
                >
            )

            if(CMAKE_PROJECT_NAME STREQUAL gbfs)
                install(TARGETS gbfs
                    LIBRARY DESTINATION lib
                )
                install(FILES "gbfs.h"
                    DESTINATION include
                )
            else()
                file(INSTALL "gbfs.h" DESTINATION "${SOURCE_DIR}/build/include")
                target_include_directories(gbfs INTERFACE "${SOURCE_DIR}/build/include")
            endif()
        else()
            add_executable(gbfs "tools/gbfs.c")

            if(CMAKE_GENERATOR MATCHES "Visual Studio")
                target_sources(gbfs PRIVATE "tools/djbasename.c")
            endif()

            install(TARGETS gbfs DESTINATION bin)
        endif()
    ]=])

    FetchContent_Declare(gbfs_proj DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        URL "http://pineight.com/gba/gbfs.zip"
        URL_MD5 "8cb0dd8e1ff0405071e2a0c58c0f76e2"
        # Update
        UPDATE_COMMAND "${CMAKE_COMMAND}" -E copy_if_different
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

    if(NOT libgbfs)
        FetchContent_MakeAvailable(gbfs_proj)
        find_library(libgbfs gbfs PATHS "${SOURCE_DIR}/build")
    endif()

    if(NOT CMAKE_GBFS_PROGRAM)
        FetchContent_GetProperties(gbfs_proj)
        if(NOT gbfs_proj_POPULATED)
            FetchContent_Populate(gbfs_proj)
        endif()

        # Configure
        execute_process(
            COMMAND ${CMAKE_COMMAND} -S . -B "${SOURCE_DIR}/build/tools"
            WORKING_DIRECTORY "${SOURCE_DIR}/source"
            RESULT_VARIABLE cmakeResult
        )

        if(cmakeResult EQUAL "1")
            message(WARNING "Failed to configure gbfs (do you have a host compiler installed?)")
        else()
            # Build
            execute_process(
                    COMMAND ${CMAKE_COMMAND} --build tools --config Release
                    WORKING_DIRECTORY "${SOURCE_DIR}/build"
                    RESULT_VARIABLE cmakeResult
            )

            if(cmakeResult EQUAL "1")
                message(WARNING "Failed to build gbfs")
            else()
                # Install
                execute_process(
                        COMMAND ${CMAKE_COMMAND} --install tools --prefix "${SOURCE_DIR}" --config Release
                        WORKING_DIRECTORY "${SOURCE_DIR}/build"
                        RESULT_VARIABLE cmakeResult
                )

                if(cmakeResult EQUAL "1")
                    message(WARNING "Failed to install gbfs")
                else()
                    find_program(CMAKE_GBFS_PROGRAM gbfs PATHS "${SOURCE_DIR}/bin")
                endif()
            endif()
        endif()
    endif()
endif()

if(libgbfs AND NOT TARGET gbfs)
    add_library(gbfs STATIC IMPORTED)
    set_property(TARGET gbfs PROPERTY IMPORTED_LOCATION "${libgbfs}")

    get_filename_component(INCLUDE_PATH "${libgbfs}" DIRECTORY)
    get_filename_component(INCLUDE_PATH "${INCLUDE_PATH}" DIRECTORY)
    target_include_directories(gbfs INTERFACE "${INCLUDE_PATH}/include")
endif()

if(NOT CMAKE_GBFS_PROGRAM)
    message(WARNING "gbfs not found: Please set `-DCMAKE_GBFS_PROGRAM:FILEPATH=<path/to/bin/gbfs>`")
endif()

function(add_gbfs)

endfunction()

unset(libgbfs CACHE)
