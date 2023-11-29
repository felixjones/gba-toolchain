#===============================================================================
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

enable_language(ASM C CXX)

include(FetchContent)

# Butano dependencies
if(NOT Python_EXECUTABLE)
    find_package(Python COMPONENTS Interpreter REQUIRED)
endif()

if(NOT CMAKE_GRIT_PROGRAM)
    find_package(grit REQUIRED)
endif()

if(NOT CMAKE_MMUTIL_PROGRAM)
    find_package(maxmod REQUIRED)
endif()

include(Bin2s)

# Find butano
find_path(BUTANO_DIR NAMES butano/butano.mak PATHS "$ENV{DEVKITPRO}/butano" "${CMAKE_SYSTEM_LIBRARY_PATH}/butano" "${BUTANO_DIR}" PATH_SUFFIXES source NO_CACHE)

if(NOT BUTANO_DIR)
    unset(BUTANO_DIR CACHE)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/butano")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    FetchContent_Declare(butano DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        SOURCE_DIR "${SOURCE_DIR}/source"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/GValiente/butano.git"
        GIT_TAG "master"
    )

    FetchContent_Populate(butano)
    if(NOT butano_SOURCE_DIR)
        message(FATAL_ERROR "Failed to fetch butano")
    endif()
    set(BUTANO_DIR "${butano_SOURCE_DIR}" CACHE PATH "Path to Butano directory" FORCE)
endif()

if(NOT EXISTS "${BUTANO_DIR}/CMakeLists.txt")
    file(WRITE "${BUTANO_DIR}/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(butano ASM C CXX)

        if(NOT CMAKE_SYSTEM_NAME STREQUAL AdvancedGameBoy)
            message(FATAL_ERROR "Butano is a library for AdvancedGameBoy")
        endif()

        # Butano is as an OBJECT library
        file(GLOB src "butano/src/*.cpp")
        file(GLOB hw_src "butano/hw/src/*.cpp")
        file(GLOB hw_asm "butano/hw/src/*.s")

        # 3rd party code
        file(GLOB_RECURSE cpp_3rd_party "butano/hw/3rd_party/*.cpp")
        file(GLOB_RECURSE c_3rd_party "butano/hw/3rd_party/*.c")
        file(GLOB_RECURSE asm_3rd_party "butano/hw/3rd_party/*.s")

        add_library(butano OBJECT ${src} ${hw_src} ${hw_asm}
            ${cpp_3rd_party}
            ${c_3rd_party}
            ${asm_3rd_party}
        )

        target_include_directories(butano PUBLIC
            "butano/include"
            "butano/hw/3rd_party/libtonc/include"
        )
        target_include_directories(butano PRIVATE
            "butano/hw/3rd_party/libugba/include"
            "butano/hw/3rd_party/maxmod/include"
        )
        target_compile_features(butano PUBLIC cxx_std_20)

        set(ARCH -mthumb -mthumb-interwork)
        set(CWARNINGS -Wall -Wextra -Wpedantic -Wshadow -Wundef -Wunused-parameter -Wmisleading-indentation -Wduplicated-cond
                -Wduplicated-branches -Wlogical-op -Wnull-dereference -Wswitch-default -Wstack-usage=16384)
        set(CFLAGS ${CWARNINGS} -gdwarf-4 -O2 -mcpu=arm7tdmi -mtune=arm7tdmi -ffast-math -ffunction-sections -fdata-sections ${ARCH})
        set(CPPWARNINGS -Wuseless-cast -Wnon-virtual-dtor -Woverloaded-virtual)

        target_compile_options(butano PRIVATE
            $<$<COMPILE_LANGUAGE:ASM>:${ARCH} -x assembler-with-cpp>
            $<$<COMPILE_LANGUAGE:C>:${CFLAGS}>
            $<$<COMPILE_LANGUAGE:CXX>:${CFLAGS} ${CPPWARNINGS} -fno-rtti -fno-exceptions -fno-threadsafe-statics -fuse-cxa-atexit>
        )

        target_compile_definitions(butano PUBLIC
            BN_TOOLCHAIN_TAG="gba-toolchain"
            BN_EWRAM_BSS_SECTION=".sbss"
            BN_IWRAM_START=__iwram_start__
            BN_IWRAM_TOP=__iwram_top
            BN_IWRAM_END=__fini_array_end
        )

        # Set IWRAM compile options
        get_target_property(iwramSources butano SOURCES)
        list(FILTER iwramSources INCLUDE REGEX ".+\\.bn_iwram\\..+")
        set_source_files_properties(${iwramSources} PROPERTIES COMPILE_FLAGS "-fno-lto -marm -mlong-calls -O2")

        # Set EWRAM compile options
        get_target_property(ewramSources butano SOURCES)
        list(FILTER ewramSources INCLUDE REGEX ".+\\.bn_ewram\\..+")
        set_source_files_properties(${ewramSources} PROPERTIES COMPILE_FLAGS "-fno-lto -O2")

        # Set no-flto compile options
        get_target_property(nofltoSources butano SOURCES)
        list(FILTER nofltoSources INCLUDE REGEX ".+\\.bn_noflto\\..+")
        set_source_files_properties(${nofltoSources} PROPERTIES COMPILE_FLAGS "-fno-lto")
    ]=])
endif()

add_subdirectory("${BUTANO_DIR}" "${CMAKE_BINARY_DIR}/lib/butano" EXCLUDE_FROM_ALL)

if(CMAKE_BIN2S_PROGRAM)
    set(bin2sCommand "${CMAKE_BIN2S_PROGRAM}")
else()
    set(bin2sCommand "${CMAKE_COMMAND}" -P "${BIN2S_SCRIPT}" --)
endif()

function(add_butano_assets target)
    set(multiValueArgs
        AUDIO
        DMG_AUDIO
        GRAPHICS
    )
    cmake_parse_arguments(ARGS "" "" "${multiValueArgs}" ${ARGN})

    set(binaryDir "${CMAKE_BINARY_DIR}/butano_${target}_assets")

    # Add audio outputs
    if(ARGS_AUDIO)
        set(byproducts"${binaryDir}/_bn_audio_files_info.txt" "${binaryDir}/_bn_audio_soundbank.bin")
        set(outputs "${binaryDir}/_bn_audio_soundbank.s")
        set(headers
            "${binaryDir}/bn_music_items.h" "${binaryDir}/bn_music_items_info.h"
            "${binaryDir}/bn_sound_items.h" "${binaryDir}/bn_sound_items_info.h"
        )
    endif()

    # Add dmg_audio outputs
    foreach(dmgAudio ${ARGS_DMG_AUDIO})
        get_filename_component(extension "${dmgAudio}" EXT)
        if(extension STREQUAL ".json")
            continue()
        endif()

        get_filename_component(name "${dmgAudio}" NAME_WE)
        if(name)
            list(APPEND outputs "${binaryDir}/${name}_bn_dmg.c")
        endif()
    endforeach()

    # Add graphics outputs
    foreach(graphics ${ARGS_GRAPHICS})
        get_filename_component(extension "${graphics}" EXT)
        if(extension STREQUAL ".json")
            continue()
        endif()

        get_filename_component(name "${graphics}" NAME_WE)
        if(name)
            list(APPEND outputs "${binaryDir}/${name}_bn_gfx.s")
            list(APPEND byproducts "${binaryDir}/_bn_${name}_graphics_file_info.txt")
        endif()
        #TODO: Support JSON file generation
    endforeach()

    if(NOT outputs AND NOT headers)
        message(FATAL_ERROR "add_butano_assets called with empty assets")
    endif()

    # Butano asset tool
    find_file(butano_assets_tool NAMES "butano_assets_tool.py" PATHS "${BUTANO_DIR}/butano/tools")
    add_custom_command(
        OUTPUT ${outputs} ${headers}
        BYPRODUCTS "${byproducts}"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${binaryDir}"
        COMMAND "${Python_EXECUTABLE}" "${butano_assets_tool}"
            --grit="${CMAKE_GRIT_PROGRAM}"
            --mmutil="${CMAKE_MMUTIL_PROGRAM}"
            --audio="${ARGS_AUDIO}"
            --dmg_audio="${ARGS_DMG_AUDIO}"
            --graphics="${ARGS_GRAPHICS}"
            --build="${binaryDir}"
        COMMAND ${bin2sCommand} "${binaryDir}/_bn_audio_soundbank.bin" > "${binaryDir}/_bn_audio_soundbank.s"
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    )

    add_library(${target} OBJECT ${outputs})
    target_include_directories(${target} INTERFACE "${binaryDir}")
endfunction()
