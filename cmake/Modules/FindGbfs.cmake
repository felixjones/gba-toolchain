include(FetchContent)

find_library(libgbfs gbfs PATHS "$ENV{DEVKITPRO}/gbfs" "${CMAKE_SYSTEM_LIBRARY_PATH}/gbfs" "${GBFS_DIR}" PATH_SUFFIXES lib)
find_program(CMAKE_GBFS_PROGRAM gbfs PATHS "$ENV{DEVKITPRO}/tools" "${CMAKE_SYSTEM_LIBRARY_PATH}/gbfs" "${GBFS_DIR}" PATH_SUFFIXES bin)
find_program(CMAKE_BIN2S_PROGRAM bin2s PATHS "$ENV{DEVKITPRO}/tools" "${CMAKE_SYSTEM_LIBRARY_PATH}/gbfs" "${GBFS_DIR}" PATH_SUFFIXES bin)

if(NOT libgbfs OR NOT CMAKE_GBFS_PROGRAM OR NOT CMAKE_BIN2S_PROGRAM)
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
                    -Wno-stringop-truncation
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
            add_executable(bin2s "tools/bin2s.c")

            if(MSVC)
                target_sources(gbfs PRIVATE "tools/djbasename.c")
            endif()

            install(TARGETS gbfs bin2s DESTINATION bin)
        endif()
    ]=])

    FetchContent_Declare(gbfs_proj DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        SOURCE_DIR "${SOURCE_DIR}/source"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        URL "http://pineight.com/gba/gbfs.zip"
        URL_MD5 "8cb0dd8e1ff0405071e2a0c58c0f76e2"
        # Update
        UPDATE_COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${SOURCE_DIR}/temp/CMakeLists.txt"
            "${SOURCE_DIR}/source/CMakeLists.txt"
    )

    if(NOT libgbfs)
        FetchContent_MakeAvailable(gbfs_proj)
        find_library(libgbfs gbfs PATHS "${SOURCE_DIR}/build")
    endif()

    if(NOT CMAKE_GBFS_PROGRAM OR NOT CMAKE_BIN2S_PROGRAM)
        FetchContent_GetProperties(gbfs_proj)
        if(NOT gbfs_proj_POPULATED)
            FetchContent_Populate(gbfs_proj)
        endif()

        if(CMAKE_HOST_WIN32)
            find_program(CMAKE_GBFS_PROGRAM gbfs PATHS "${SOURCE_DIR}/source/tools")
            find_program(CMAKE_BIN2S_PROGRAM bin2s PATHS "${SOURCE_DIR}/source/tools")
        endif()
    endif()

    if(NOT CMAKE_GBFS_PROGRAM OR NOT CMAKE_BIN2S_PROGRAM)
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
                    find_program(CMAKE_BIN2S_PROGRAM bin2s PATHS "${SOURCE_DIR}/bin")
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

if(NOT CMAKE_BIN2S_PROGRAM)
    message(WARNING "bin2s not found: Please set `-DCMAKE_BIN2S_PROGRAM:FILEPATH=<path/to/bin/bin2s>`")
endif()

function(add_gbfs_archive target)
    set(ASSETS $<TARGET_GENEX_EVAL:${target},$<TARGET_PROPERTY:${target},ASSETS>>)

    add_custom_command(
        OUTPUT ${target}.s
        BYPRODUCTS ${target}.gbfs
        COMMAND "${CMAKE_GBFS_PROGRAM}" "${CMAKE_BINARY_DIR}/${target}.gbfs" ${ASSETS}
        COMMAND "${CMAKE_BIN2S_PROGRAM}" "${CMAKE_BINARY_DIR}/${target}.gbfs" > "${CMAKE_BINARY_DIR}/${target}.s"
        DEPENDS ${ASSETS}
        VERBATIM
        COMMAND_EXPAND_LISTS
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        COMMENT "Generating ${target}"
    )

    enable_language(ASM)
    add_library(${target} OBJECT ${target}.s)

    set_target_properties(${target} PROPERTIES
        ASSETS "${ARGN}"
        GBFS_FILE "${target}.gbfs"
    )
endfunction()

unset(libgbfs CACHE)
