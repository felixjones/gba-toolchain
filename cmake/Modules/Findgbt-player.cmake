#===============================================================================
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

enable_language(ASM C)

include(FetchContent)

find_library(libgbt_player gbt_player PATHS "${CMAKE_SYSTEM_LIBRARY_PATH}/gbt_player" "${GBT_PLAYER_DIR}" PATH_SUFFIXES lib)

if(NOT libgbt_player)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/gbt_player")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/include")
    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    file(WRITE "${SOURCE_DIR}/temp/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(gbt_player C)

        add_library(gbt-player STATIC "gba/gbt_player/gbt_player.c")

        target_compile_options(gbt-player PRIVATE
            $<$<COMPILE_LANGUAGE:C>:-mthumb -O2
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

        if(CMAKE_PROJECT_NAME STREQUAL gbt_player)
            install(TARGETS gbt-player
                LIBRARY DESTINATION lib
            )
            install(FILES "gba/gbt_player/gbt_hardware.h" "gba/gbt_player/gbt_player.h"
                DESTINATION include
            )
        else()
            file(INSTALL "gba/gbt_player/gbt_hardware.h" "gba/gbt_player/gbt_player.h" DESTINATION "${SOURCE_DIR}/build/include")
            target_include_directories(gbt-player INTERFACE "${SOURCE_DIR}/build/include")
        endif()
    ]=])

    ExternalProject_Add(gbt_player_proj
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/AntonioND/gbt-player.git"
        GIT_TAG "master"
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
        BUILD_BYPRODUCTS "${SOURCE_DIR}/build/libgbt-player.a"
        # Install
        INSTALL_DIR "${SOURCE_DIR}"
    )

    add_library(gbt-player STATIC IMPORTED)
    add_dependencies(gbt-player gbt_player_proj)
    set_property(TARGET gbt-player PROPERTY IMPORTED_LOCATION "${SOURCE_DIR}/build/libgbt-player.a")
    target_include_directories(gbt-player INTERFACE "${SOURCE_DIR}/include")
else()
    add_library(gbt-player STATIC IMPORTED)
    set_property(TARGET gbt-player PROPERTY IMPORTED_LOCATION "${libgbt_player}")

    get_filename_component(INCLUDE_PATH "${libgbt_player}" DIRECTORY)
    get_filename_component(INCLUDE_PATH "${INCLUDE_PATH}" DIRECTORY)
    target_include_directories(gbt-player INTERFACE "${INCLUDE_PATH}/include")
endif()

unset(libgbt_player CACHE)

# gbt-player tools
if(NOT Python_EXECUTABLE)
    find_package(Python COMPONENTS Interpreter REQUIRED)
endif()

find_file(s3m2gbt NAMES "gba/s3m2gbt/s3m2gbt.py" PATHS "${CMAKE_SYSTEM_LIBRARY_PATH}/gbt_player" "${GBT_PLAYER_DIR}" PATH_SUFFIXES source NO_CACHE)
find_file(mod2gbt NAMES "gba/mod2gbt/mod2gbt.py" PATHS "${CMAKE_SYSTEM_LIBRARY_PATH}/gbt_player" "${GBT_PLAYER_DIR}" PATH_SUFFIXES source NO_CACHE)
function(add_gbt_assets target)
    foreach(input ${ARGN})
        get_filename_component(name ${input} NAME_WE)
        get_filename_component(ext ${input} LAST_EXT)
        set(output "${name}.c")

        if(ext STREQUAL ".s3m")
            add_custom_command(
                OUTPUT "${output}"
                COMMAND "${CMAKE_COMMAND}" -E env "${Python_EXECUTABLE}" "${s3m2gbt}"
                    --input "${input}"
                    --name "${target}_${name}"
                    --output "${CMAKE_BINARY_DIR}/${output}"
                    --instruments
                WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            )
        elseif(ext STREQUAL ".mod")
            add_custom_command(
                OUTPUT "${output}"
                COMMAND "${CMAKE_COMMAND}" -E env "${Python_EXECUTABLE}" "${mod2gbt}"
                    "${CMAKE_SOURCE_DIR}/${input}" "${target}_${name}"
                COMMAND "${CMAKE_COMMAND}" -E rename "${target}_${output}" "${output}"
                WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
            )
        else()
            message(FATAL_ERROR "${input} must be .s3m or .mod format")
        endif()
        list(APPEND outputs ${output})
    endforeach()

    add_library(${target} OBJECT ${outputs})
endfunction()

find_file(s3msplit NAMES "gba/s3msplit/s3msplit.py" PATHS "${CMAKE_SYSTEM_LIBRARY_PATH}/gbt_player" "${GBT_PLAYER_DIR}" PATH_SUFFIXES source NO_CACHE)
function(add_gbt_maxmod_assets target)
    find_package(maxmod REQUIRED)

    foreach(input ${ARGN})
        get_filename_component(name ${input} NAME_WE)
        get_filename_component(ext ${input} LAST_EXT)
        set(output "${name}.c")

        if(ext STREQUAL ".s3m")
            add_custom_command(
                OUTPUT "${output}" "${name}_dma.s3m"
                BYPRODUCTS "${name}_psg.s3m"
                COMMAND "${CMAKE_COMMAND}" -E env "${Python_EXECUTABLE}" "${s3msplit}"
                    --input "${input}"
                    --psg "${CMAKE_BINARY_DIR}/${name}_psg.s3m"
                    --dma "${CMAKE_BINARY_DIR}/${name}_dma.s3m"
                COMMAND "${CMAKE_COMMAND}" -E env "${Python_EXECUTABLE}" "${s3m2gbt}"
                    --input "${CMAKE_BINARY_DIR}/${name}_psg.s3m"
                    --name "${target}_${name}"
                    --output "${CMAKE_BINARY_DIR}/${output}"
                    --instruments
                WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            )
            list(APPEND outputs ${output})
            list(APPEND dma "${name}_dma.s3m")
        else()
            message(FATAL_ERROR "${input} must be .s3m format")
        endif()
    endforeach()

    if(CMAKE_BIN2S_PROGRAM)
        set(bin2sCommand "${CMAKE_BIN2S_PROGRAM}")
    else()
        set(bin2sCommand "${CMAKE_COMMAND}" -P "${BIN2S_SCRIPT}" --)
    endif()

    add_custom_command(
        OUTPUT "${target}.s" "soundbank/${target}.h"
        BYPRODUCTS "${target}.bin"
        DEPENDS ${dma}
        COMMAND "${CMAKE_COMMAND}" -E make_directory "soundbank"
        COMMAND "${CMAKE_MMUTIL_PROGRAM}" -o${target}.bin -hsoundbank/${target}.h ${dma}
        COMMAND ${bin2sCommand}  "${target}.bin" > "${target}.s"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    )

    add_library(${target} OBJECT ${outputs} "${target}.s")
    target_include_directories(${target} INTERFACE ${CMAKE_BINARY_DIR})
endfunction()
