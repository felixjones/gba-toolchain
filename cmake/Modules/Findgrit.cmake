#===============================================================================
#
# Provides the CMake functions for adding a grit assets target:
#   `add_grit_tilemap`, `add_grit_sprite`, and `add_grit_bitmap`
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

enable_language(ASM C)

include(FetchContent)

find_program(CMAKE_GRIT_PROGRAM grit grit.exe PATHS "$ENV{DEVKITPRO}/tools" "${CMAKE_SYSTEM_LIBRARY_PATH}/grit" "${GRIT_DIR}" PATH_SUFFIXES bin)

if(NOT CMAKE_GRIT_PROGRAM)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/grit")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    file(WRITE "${SOURCE_DIR}/temp/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(grit VERSION 0.9.2 LANGUAGES CXX)

        if(TOOLCHAIN_MODULE_PATH)
            list(APPEND CMAKE_MODULE_PATH ${TOOLCHAIN_MODULE_PATH})
        endif()
        find_package(FreeImage REQUIRED)

        add_library(cldib STATIC
            cldib/cldib_adjust.cpp
            cldib/cldib_conv.cpp
            cldib/cldib_core.cpp
            cldib/cldib_tmap.cpp
            cldib/cldib_tools.cpp
            cldib/cldib_wu.cpp
        )
        target_include_directories(cldib PUBLIC cldib)

        add_library(libgrit STATIC
            libgrit/cprs.cpp
            libgrit/cprs_huff.cpp
            libgrit/cprs_lz.cpp
            libgrit/cprs_rle.cpp
            libgrit/grit_core.cpp
            libgrit/grit_misc.cpp
            libgrit/grit_prep.cpp
            libgrit/grit_shared.cpp
            libgrit/grit_xp.cpp
            libgrit/logger.cpp
            libgrit/pathfun.cpp
        )
        set_target_properties(libgrit PROPERTIES PREFIX "")
        target_include_directories(libgrit PUBLIC libgrit .)
        target_link_libraries(libgrit PUBLIC cldib)
        target_compile_definitions(libgrit PUBLIC PACKAGE_VERSION="${CMAKE_PROJECT_VERSION}")

        add_executable(grit
            srcgrit/cli.cpp
            srcgrit/grit_main.cpp
            extlib/fi.cpp
        )
        target_include_directories(grit PRIVATE extlib)
        target_link_libraries(grit PRIVATE
            libgrit
            freeimage::FreeImage
            $<$<NOT:$<BOOL:MSVC>>:m>
        )

        install(TARGETS grit DESTINATION bin)
    ]=])

    FetchContent_Declare(grit_proj DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        SOURCE_DIR "${SOURCE_DIR}/source"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/devkitPro/grit.git"
        GIT_TAG "master"
        # Update
        UPDATE_COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${SOURCE_DIR}/temp/CMakeLists.txt"
            "${SOURCE_DIR}/source/CMakeLists.txt"
    )

    FetchContent_Populate(grit_proj)

    # Configure
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -S . -B "${SOURCE_DIR}/build"
            "-DTOOLCHAIN_MODULE_PATH=${CMAKE_MODULE_PATH}"
            "-DTOOLCHAIN_LIBRARY_PATH=${CMAKE_SYSTEM_LIBRARY_PATH}"
        WORKING_DIRECTORY "${SOURCE_DIR}/source"
        RESULT_VARIABLE cmakeResult
    )

    if(cmakeResult EQUAL "1")
        message(WARNING "Failed to configure grit")
    else()
        # Build
        execute_process(
            COMMAND "${CMAKE_COMMAND}" --build . --config Release
            WORKING_DIRECTORY "${SOURCE_DIR}/build"
            RESULT_VARIABLE cmakeResult
        )

        if(cmakeResult EQUAL "1")
            message(WARNING "Failed to build grit")
        else()
            # Install
            execute_process(
                COMMAND ${CMAKE_COMMAND} --install . --prefix "${SOURCE_DIR}" --config Release
                WORKING_DIRECTORY "${SOURCE_DIR}/build"
                RESULT_VARIABLE cmakeResult
            )

            if(cmakeResult EQUAL "1")
                message(WARNING "Failed to install grit")
            else()
                find_program(CMAKE_GRIT_PROGRAM grit PATHS "${SOURCE_DIR}/bin")
            endif()
        endif()
    endif()
endif()

if(NOT CMAKE_GRIT_PROGRAM)
    message(WARNING "grit not found: Please set `-DCMAKE_GRIT_PROGRAM:FILEPATH=<path/to/bin/grit>`")
endif()

function(add_grit_tilemap target type)
    file(RELATIVE_PATH inpath "${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}")
    set(outpath "${CMAKE_CURRENT_BINARY_DIR}")

    set(oneValueArgs
        SHARED_PREFIX # File to use for shared output (default is target name when sharing is used)
        LOG_LEVEL # 1, 2, or 3 (default is 1)
        DATA_TYPE # Default data type (individual options can override this) u8, u16, or u32
        OPTIONS_FILE # File to read in additional options
    )
    set(multiValueArgs
        GRAPHICS
        PALETTE
        MAP
        --
    )
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    grit_parse_arguments_graphics(ARGS_GFX optGfx ${ARGS_GRAPHICS})
    grit_parse_arguments_palette(ARGS_PAL optPal ${ARGS_PALETTE})
    grit_parse_arguments_map(ARGS_MAP optMap ${ARGS_MAP})

    list(APPEND ARGS_UNPARSED_ARGUMENTS ${ARGS_GFX_UNPARSED_ARGUMENTS})
    list(APPEND ARGS_UNPARSED_ARGUMENTS ${ARGS_PAL_UNPARSED_ARGUMENTS})
    list(APPEND ARGS_UNPARSED_ARGUMENTS ${ARGS_MAP_UNPARSED_ARGUMENTS})
    list(APPEND ARGS_UNPARSED_ARGUMENTS ${ARGS_--})
    set(ARGN ${ARGS_UNPARSED_ARGUMENTS})

    # Tilemap options

    set(opts "-gt") # Tilemap mode

    if(NOT ARGS_GFX_BIT_DEPTH)
        list(APPEND opts "-gB4") # Default to 4bpp tile graphics
    endif()
    if(NOT ARGS_MAP_LAYOUT)
        list(APPEND opts "-mLs") # Default to SBB layout
    endif()
    if(NOT ARGS_MAP_OPTIMIZE)
        if(ARGS_GFX_BIT_DEPTH EQUAL 8)
            if(ARGS_MAP_LAYOUT STREQUAL AFFINE)
                list(APPEND opts "-mRa") # Optimise for affine
            else()
                list(APPEND opts "-mR8") # Optimise for 8bpp
            endif()
        elseif(NOT ARGS_GFX_BIT_DEPTH OR ARGS_GFX_BIT_DEPTH EQUAL 4)
            list(APPEND opts "-mR4") # Optimise for 4bpp
        endif()
    endif()

    if(type STREQUAL C)
        set(suffix ".c")
        list(APPEND opts "-ftc")
    elseif(type STREQUAL ASM)
        set(suffix ".s")
        list(APPEND opts "-fts")
    elseif(type STREQUAL BIN OR type STREQUAL BINARY)
        set(palsuffix ".pal.bin")
        set(imgsuffix ".img.bin")
        set(mapsuffix ".map.bin")
        list(APPEND opts "-ftb" "-fh!")
    elseif(type STREQUAL GBFS)
        set(suffix ".gbfs")
        list(APPEND opts "-ftg" "-fh!")
    else()
        message(FATAL_ERROR "Unknown grit output type '${type}'")
    endif()

    # Common file options

    if(ARGS_SHARED_PREFIX)
        list(APPEND opts "-O${ARGS_SHARED_PREFIX}")
    elseif(ARGS_GFX_SHARED OR ARGS_PAL_SHARED)
        list(APPEND opts "-O${target}")
    endif()

    if(ARGS_LOG_LEVEL EQUAL 1)
        list(APPEND opts "-W1")
    elseif(ARGS_LOG_LEVEL EQUAL 2)
        list(APPEND opts "-W2")
    elseif(ARGS_LOG_LEVEL EQUAL 3)
        list(APPEND opts "-W3")
    elseif(ARGS_LOG_LEVEL)
        message(WARNING "Invalid grit log level '${ARGS_LOG_LEVEL}'. Must be '1', '2', or '3'.")
    endif()

    if(ARGS_DATA_TYPE MATCHES "^[uU]8$")
        list(APPEND opts "-U8")
    elseif(ARGS_DATA_TYPE MATCHES "^[uU]16$")
        list(APPEND opts "-U16")
    elseif(ARGS_DATA_TYPE MATCHES "^[uU]32$")
        list(APPEND opts "-U32")
    elseif(ARGS_DATA_TYPE)
        message(WARNING "Invalid grit data type '${ARGS_DATA_TYPE}'. Must be 'u8', 'u16', or 'u32'.")
    endif()

    if(ARGS_COMPRESSION STREQUAL OFF OR ARGS_COMPRESSION STREQUAL NONE)
        list(APPEND opts "-Z!")
    elseif(ARGS_COMPRESSION STREQUAL LZ77)
        list(APPEND opts "-Zl")
    elseif(ARGS_COMPRESSION STREQUAL HUFF OR ARGS_COMPRESSION STREQUAL HUFFMAN)
        list(APPEND opts "-Zh")
    elseif(ARGS_COMPRESSION STREQUAL RLE OR ARGS_COMPRESSION STREQUAL RUN_LENGTH_ENCODING)
        list(APPEND opts "-Zr")
    elseif(ARGS_COMPRESSION)
        message(WARNING "Invalid grit compression type '${ARGS_COMPRESSION}'. Must be 'OFF', 'LZ77', 'HUFF', or 'RLE'.")
    endif()

    list(APPEND opts ${optGfx} ${optPal} ${optMap})

    if(ARGS_OPTIONS_FILE)
        if(IS_ABSOLUTE ${ARGS_OPTIONS_FILE})
            list(APPEND opts "-ff${ARGS_OPTIONS_FILE}")
        else()
            list(APPEND opts "-ff${inpath}/${ARGS_OPTIONS_FILE}")
        endif()
    endif()

    # Setup the output files

    if(suffix)
        macro(append_output prefix operation)
            list(APPEND output "${outpath}/${prefix}${suffix}")
            if(type STREQUAL C OR type STREQUAL ASM)
                list(APPEND output "${outpath}/${prefix}.h") # TODO : Header exclude support?
            endif()
        endmacro()
    else()
        macro(append_output prefix operation)
            if(NOT ARGS_MAP_EXCLUDE AND ${operation} ARGS_MAP_SHARED)
                list(APPEND output "${outpath}/${prefix}${mapsuffix}")
            endif()
            if(NOT ARGS_PAL_EXCLUDE AND ${operation} ARGS_PAL_SHARED)
                list(APPEND output "${outpath}/${prefix}${palsuffix}")
            endif()
            if(NOT ARGS_GFX_EXCLUDE AND ${operation} ARGS_GFX_SHARED)
                list(APPEND output "${outpath}/${prefix}${imgsuffix}")
            endif()
        endmacro()
    endif()

    if(ARGS_SHARED_PREFIX)
        append_output(${ARGS_SHARED_PREFIX} "")
    elseif(ARGS_GFX_SHARED OR ARGS_PAL_SHARED OR ARGS_MAP_SHARED)
        append_output(${target} "")
    endif()

    foreach(arg ${ARGN})
        if(arg MATCHES "[$][<]TARGET_[A-Z_]+[:].+[>]")
            message(WARNING "Tried to set genex '${arg}' as an output for '${target}'")
            continue()
        endif()
        if(arg MATCHES "[$][<][A-Z_]+[:].+[>]")
            list(APPEND input "${arg}") # Copy any valid generator expression
        else()
            if(IS_ABSOLUTE ${arg})
                list(APPEND input "${arg}")
            else()
                list(APPEND input "${inpath}/${arg}")
            endif()
            # Parse the file and expected output types to produce output names
            get_filename_component(arg "${arg}" NAME_WE)
            append_output(${arg} NOT)
        endif()
    endforeach()

    # Setup the grit command

    add_custom_command(
        OUTPUT ${output}
        COMMAND "${CMAKE_GRIT_PROGRAM}" ${input} ${opts}
        DEPENDS ${input}
        VERBATIM
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    )

    # Setup the target

    if(type STREQUAL C OR type STREQUAL ASM)
        add_library(${target} OBJECT ${output})
        target_include_directories(${target} INTERFACE "${CMAKE_CURRENT_BINARY_DIR}")
    else()
        add_custom_target(${target} DEPENDS ${output})
        set_target_properties(${target} PROPERTIES OBJECTS "${output}")
    endif()
endfunction()

function(add_grit_sprite target type)
    set(args MAP EXCLUDE ${ARGN})
    add_grit_tilemap(${target} ${type} ${args})
endfunction()

function(add_grit_bitmap target type)
    file(RELATIVE_PATH inpath "${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}")
    set(outpath "${CMAKE_CURRENT_BINARY_DIR}")

    set(oneValueArgs
        SHARED_PREFIX # File to use for shared output (default is target name when sharing is used)
        LOG_LEVEL # 1, 2, or 3 (default is 1)
        DATA_TYPE # Default data type (individual options can override this) u8, u16, or u32
        COMPRESSION # Default compression type (individual options can override this)
        OPTIONS_FILE # File to read in additional options
    )
    set(multiValueArgs
        GRAPHICS
        PALETTE
        --
    )
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    grit_parse_arguments_graphics(ARGS_GFX optGfx ${ARGS_GRAPHICS})
    grit_parse_arguments_palette(ARGS_PAL optPal ${ARGS_PALETTE})

    list(APPEND ARGS_UNPARSED_ARGUMENTS ${ARGS_GFX_UNPARSED_ARGUMENTS})
    list(APPEND ARGS_UNPARSED_ARGUMENTS ${ARGS_PAL_UNPARSED_ARGUMENTS})
    list(APPEND ARGS_UNPARSED_ARGUMENTS ${ARGS_--})
    set(ARGN ${ARGS_UNPARSED_ARGUMENTS})

    # Bitmap options

    set(opts "-gb") # Bitmap mode

    if(type STREQUAL C)
        set(suffix ".c")
        list(APPEND opts "-ftc")
    elseif(type STREQUAL ASM)
        set(suffix ".s")
        list(APPEND opts "-fts")
    elseif(type STREQUAL BIN OR type STREQUAL BINARY)
        set(palsuffix ".pal.bin")
        set(imgsuffix ".img.bin")
        list(APPEND opts "-ftb" "-fh!")
    elseif(type STREQUAL GBFS)
        set(suffix ".gbfs")
        list(APPEND opts "-ftg" "-fh!")
    else()
        message(FATAL_ERROR "Unknown grit output type '${type}'")
    endif()

    # Common file options

    if(ARGS_SHARED_PREFIX)
        list(APPEND opts "-O${ARGS_SHARED_PREFIX}")
    elseif(ARGS_GFX_SHARED OR ARGS_PAL_SHARED)
        list(APPEND opts "-O${target}")
    endif()

    if(ARGS_LOG_LEVEL EQUAL 1)
        list(APPEND opts "-W1")
    elseif(ARGS_LOG_LEVEL EQUAL 2)
        list(APPEND opts "-W2")
    elseif(ARGS_LOG_LEVEL EQUAL 3)
        list(APPEND opts "-W3")
    elseif(ARGS_LOG_LEVEL)
        message(WARNING "Invalid grit log level '${ARGS_LOG_LEVEL}'. Must be '1', '2', or '3'.")
    endif()

    if(ARGS_DATA_TYPE MATCHES "^[uU]8$")
        list(APPEND opts "-U8")
    elseif(ARGS_DATA_TYPE MATCHES "^[uU]16$")
        list(APPEND opts "-U16")
    elseif(ARGS_DATA_TYPE MATCHES "^[uU]32$")
        list(APPEND opts "-U32")
    elseif(ARGS_DATA_TYPE)
        message(WARNING "Invalid grit data type '${ARGS_DATA_TYPE}'. Must be 'u8', 'u16', or 'u32'.")
    endif()

    if(ARGS_COMPRESSION STREQUAL OFF OR ARGS_COMPRESSION STREQUAL NONE)
        list(APPEND opts "-Z!")
    elseif(ARGS_COMPRESSION STREQUAL LZ77)
        list(APPEND opts "-Zl")
    elseif(ARGS_COMPRESSION STREQUAL HUFF OR ARGS_COMPRESSION STREQUAL HUFFMAN)
        list(APPEND opts "-Zh")
    elseif(ARGS_COMPRESSION STREQUAL RLE OR ARGS_COMPRESSION STREQUAL RUN_LENGTH_ENCODING)
        list(APPEND opts "-Zr")
    elseif(ARGS_COMPRESSION)
        message(WARNING "Invalid grit compression type '${ARGS_COMPRESSION}'. Must be 'OFF', 'LZ77', 'HUFF', or 'RLE'.")
    endif()

    list(APPEND opts ${optGfx} ${optPal})

    if(ARGS_OPTIONS_FILE)
        if(IS_ABSOLUTE ARGS_OPTIONS_FILE)
            list(APPEND opts "-ff${ARGS_OPTIONS_FILE}")
        else()
            list(APPEND opts "-ff${inpath}/${ARGS_OPTIONS_FILE}")
        endif()
    endif()

    # Setup the output files

    if(suffix)
        macro(append_output prefix operation)
            list(APPEND output "${outpath}/${prefix}${suffix}")
            if(type STREQUAL C OR type STREQUAL ASM)
                list(APPEND output "${outpath}/${prefix}.h") # TODO : Header exclude support?
            endif()
        endmacro()
    else()
        macro(append_output prefix operation)
            if(NOT ARGS_PAL_EXCLUDE AND ${operation} ARGS_PAL_SHARED)
                list(APPEND output "${outpath}/${prefix}${palsuffix}")
            endif()
            if(NOT ARGS_GFX_EXCLUDE AND ${operation} ARGS_GFX_SHARED)
                list(APPEND output "${outpath}/${prefix}${imgsuffix}")
            endif()
        endmacro()
    endif()

    if(ARGS_SHARED_PREFIX)
        append_output(${ARGS_SHARED_PREFIX} "")
    elseif(ARGS_GFX_SHARED OR ARGS_PAL_SHARED)
        append_output(${target} "")
    endif()

    foreach(arg ${ARGN})
        if(arg MATCHES "[$][<]TARGET_[A-Z_]+[:].+[>]")
            message(WARNING "Tried to set genex '${arg}' as an output for '${target}'")
            continue()
        endif()
        if(arg MATCHES "[$][<][A-Z_]+[:].+[>]")
            list(APPEND input "${arg}") # Copy any valid generator expression
        else()
            if(IS_ABSOLUTE ${arg})
                list(APPEND input "${arg}")
            else()
                list(APPEND input "${inpath}/${arg}")
            endif()
            # Parse the file and expected output types to produce output names
            get_filename_component(arg "${arg}" NAME_WE)
            append_output(${arg} NOT)
        endif()
    endforeach()

    # Setup the grit command

    add_custom_command(
        OUTPUT ${output}
        COMMAND "${CMAKE_GRIT_PROGRAM}" ${input} ${opts}
        DEPENDS ${input}
        VERBATIM
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    )

    # Setup the target

    if(type STREQUAL C OR type STREQUAL ASM)
        add_library(${target} OBJECT ${output})
        target_include_directories(${target} INTERFACE "${CMAKE_CURRENT_BINARY_DIR}")
    else()
        add_custom_target(${target} DEPENDS ${output})
        set_target_properties(${target} PROPERTIES OBJECTS "${output}")
    endif()
endfunction()

macro(grit_copy_arguments dest source arguments)
    foreach(arg ${arguments})
        set(${dest}_${arg} ${${source}_${arg}} PARENT_SCOPE)
    endforeach()
endmacro()

macro(grit_copy_parsed_arguments dest source options oneValueArgs multiValueArgs)
    grit_copy_arguments(${dest} ${source} "${options}")
    grit_copy_arguments(${dest} ${source} "${oneValueArgs}")
    grit_copy_arguments(${dest} ${source} "${multiValueArgs}")
    set(${dest}_UNPARSED_ARGUMENTS ${${source}_UNPARSED_ARGUMENTS} PARENT_SCOPE)
endmacro()

function(grit_parse_arguments_common prefix x outOptions outArgs)
    set(options
        EXCLUDE # Don't generate this type (overrides everything else)
        SHARED # Should this use the shared file (see SHARED_PREFIX)
    )
    set(oneValueArgs
        DATA_TYPE # u8, u16, or u32
        COMPRESSION
    )
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "" ${ARGN})

    if(ARGS_EXCLUDE)
        list(APPEND opts "-${x}!")
    endif()
    if(ARGS_SHARED)
        list(APPEND opts "-${x}S")
    endif()
    if(ARGS_DATA_TYPE MATCHES "^[uU]8$")
        list(APPEND opts "-${x}u8")
    elseif(ARGS_DATA_TYPE MATCHES "^[uU]16$")
        list(APPEND opts "-${x}u16")
    elseif(ARGS_DATA_TYPE MATCHES "^[uU]32$")
        list(APPEND opts "-${x}u32")
    elseif(ARGS_DATA_TYPE)
        message(WARNING "Invalid grit data type '${ARGS_DATA_TYPE}'. Must be 'u8', 'u16', or 'u32'.")
    endif()
    if(ARGS_COMPRESSION STREQUAL OFF OR ARGS_COMPRESSION STREQUAL NONE)
        list(APPEND opts "-${x}z!")
    elseif(ARGS_COMPRESSION STREQUAL LZ77)
        list(APPEND opts "-${x}zl")
    elseif(ARGS_COMPRESSION STREQUAL HUFF OR ARGS_COMPRESSION STREQUAL HUFFMAN)
        list(APPEND opts "-${x}zh")
    elseif(ARGS_COMPRESSION STREQUAL RLE OR ARGS_COMPRESSION STREQUAL RUN_LENGTH_ENCODING)
        list(APPEND opts "-${x}zr")
    elseif(ARGS_COMPRESSION)
        message(WARNING "Invalid grit compression type '${ARGS_COMPRESSION}'. Must be 'OFF', 'LZ77', 'HUFF', or 'RLE'.")
    endif()

    grit_copy_parsed_arguments(${prefix} ARGS "${options}" "${oneValueArgs}" "")
    set(${outArgs} ${options} ${oneValueArgs} PARENT_SCOPE)
    set(${outOptions} ${opts} PARENT_SCOPE)
endfunction()

function(grit_parse_arguments_graphics prefix outOptions)
    grit_parse_arguments_common(ARGS g opts commonArgs ${ARGN})
    set(ARGN ${ARGS_UNPARSED_ARGUMENTS})

    set(oneValueArgs
        BIT_DEPTH
        TRANSPARENT_COLOR
    )
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "" ${ARGN})

    if(ARGS_BIT_DEPTH EQUAL 1 OR ARGS_BIT_DEPTH EQUAL 2 OR ARGS_BIT_DEPTH EQUAL 4 OR ARGS_BIT_DEPTH EQUAL 8 OR ARGS_BIT_DEPTH EQUAL 16)
        list(APPEND opts "-gB${ARGS_BIT_DEPTH}")
    elseif(ARGS_BIT_DEPTH)
        message(FATAL_ERROR "Unknown bit depth '${ARGS_BIT_DEPTH}'")
    endif()

    if(ARGS_TRANSPARENT_COLOR)
        list(APPEND opts "-gT${ARGS_TRANSPARENT_COLOR}")
    endif()

    grit_copy_arguments(${prefix} ARGS "${commonArgs}")
    grit_copy_parsed_arguments(${prefix} ARGS "" "${oneValueArgs}" "")

    set(${outOptions} ${opts} PARENT_SCOPE)
endfunction()

function(grit_parse_arguments_palette prefix outOptions)
    grit_parse_arguments_common(ARGS p opts commonArgs ${ARGN})
    set(ARGN ${ARGS_UNPARSED_ARGUMENTS})

    set(oneValueArgs
        START
        END
        TRANSPARENT_INDEX
    )
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "" ${ARGN})

    if(ARGS_START)
        list(APPEND opts "-ps${ARGS_START}")
    endif()
    if(ARGS_END)
        list(APPEND opts "-pe${ARGS_END}")
    endif()

    if(ARGS_TRANSPARENT_INDEX MATCHES "[0-9]+")
        list(APPEND opts "-pT${ARGS_TRANSPARENT_INDEX}")
    elseif(ARGS_TRANSPARENT_INDEX)
        message(FATAL_ERROR "Transparent index '${ARGS_TRANSPARENT_INDEX}' is not a valid number")
    endif()

    grit_copy_arguments(${prefix} ARGS "${commonArgs}")
    grit_copy_parsed_arguments(${prefix} ARGS "" "${oneValueArgs}" "")

    set(${outOptions} ${opts} PARENT_SCOPE)
endfunction()

function(grit_parse_arguments_map prefix outOptions)
    grit_parse_arguments_common(ARGS m opts commonArgs ${ARGN})
    set(ARGN ${ARGS_UNPARSED_ARGUMENTS})

    set(oneValueArgs
        LAYOUT
        ENTRY_OFFSET
    )
    set(multiValueArgs
        OPTIMIZE
    )
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(ARGS_LAYOUT STREQUAL FLAT)
        list(APPEND opts "-mLf")
    elseif(ARGS_LAYOUT STREQUAL SBB)
        list(APPEND opts "-mLs")
    elseif(ARGS_LAYOUT STREQUAL AFFINE)
        list(APPEND opts "-mLa")
    elseif(ARGS_LAYOUT)
        message(FATAL_ERROR "Unknown map layout '${ARGS_LAYOUT}'")
    endif()

    if(ARGS_ENTRY_OFFSET MATCHES "[0-9]+")
        list(APPEND opts "-ma${ARGS_ENTRY_OFFSET}")
    elseif(ARGS_TRANSPARENT_INDEX)
        message(FATAL_ERROR "Entry offset '${ARGS_ENTRY_OFFSET}' is not a valid number")
    endif()

    if(ARGS_OPTIMIZE STREQUAL NONE)
        list(APPEND opts "-mR!")
    elseif(ARGS_OPTIMIZE STREQUAL ALL)
        list(APPEND opts "-mRtpf")
    elseif(ARGS_OPTIMIZE)
        foreach(arg ${ARGS_OPTIMIZE})
            if(arg STREQUAL TILES)
                string(APPEND optimize "t")
            elseif(arg STREQUAL PALETTES)
                string(APPEND optimize "p")
            elseif(arg STREQUAL FLIPPED)
                string(APPEND optimize "f")
            elseif(arg STREQUAL NONE)
                string(APPEND optimize "!")
            elseif(arg)
                message(FATAL_ERROR "Unknown map optimize level '${arg}'. Must be `TILES`, `PALETTES`, or `FLIPPED`.")
            endif()
        endforeach()
        list(APPEND opts "-mR${optimize}")
    endif()

    grit_copy_arguments(${prefix} ARGS "${commonArgs}")
    grit_copy_parsed_arguments(${prefix} ARGS "" "${oneValueArgs}" "${multiValueArgs}")

    set(${outOptions} ${opts} PARENT_SCOPE)
endfunction()
