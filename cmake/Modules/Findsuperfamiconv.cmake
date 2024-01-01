#===============================================================================
#
# Provides the CMake function `add_superfamiconv_graphics` for adding a superfamiconv assets target
#
#   The `OUTPUT_FILES` property can be used as file dependencies
#
#   Example:
#   ```cmake
#   # Generate palettes & tiles for sprites
#   add_superfamiconv_graphics(sprites PALETTE TILES SPRITE_MODE
#       path/to/my/sprite.png
#       path/to/another/sprite.png
#   )
#   get_target_property(sprite_files sprites OUTPUT_FILES)
#
#   # Generate palettes, tiles & maps for backgrounds
#   add_superfamiconv_graphics(backgrounds PALETTE TILES MAP
#       path/to/my/background.png
#       path/to/another/background.png
#   )
#   get_target_property(background_files backgrounds OUTPUT_FILES)
#
#   # Or individually access the palettes, tiles, maps
#   get_target_property(background_palettes backgrounds PALETTE_FILES)
#   get_target_property(background_tiles backgrounds TILES_FILES)
#   get_target_property(background_maps backgrounds MAP_FILES)
#   ```
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include(FetchContent)

find_program(CMAKE_SUPERFAMICONV_PROGRAM superfamiconv superfamiconv.exe PATHS "${CMAKE_SYSTEM_LIBRARY_PATH}/superfamiconv" "${SUPERFAMICONV_DIR}" PATH_SUFFIXES bin)

if(NOT CMAKE_SUPERFAMICONV_PROGRAM)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/superfamiconv")

    FetchContent_Declare(superfamiconv_proj DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        SOURCE_DIR "${SOURCE_DIR}/source"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/Optiroc/SuperFamiconv.git"
        GIT_TAG "master"
    )

    FetchContent_MakeAvailable(superfamiconv_proj)

    # Configure
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -S . -B "${SOURCE_DIR}/build"
        WORKING_DIRECTORY "${SOURCE_DIR}/source"
        RESULT_VARIABLE cmakeResult
    )

    if(cmakeResult EQUAL "1")
        message(WARNING "Failed to configure superfamiconv")
    else()
        # Build
        execute_process(
            COMMAND "${CMAKE_COMMAND}" --build . --config Release
            WORKING_DIRECTORY "${SOURCE_DIR}/build"
            RESULT_VARIABLE cmakeResult
        )

        if(cmakeResult EQUAL "1")
            message(WARNING "Failed to build superfamiconv")
        else()
            # Install
            execute_process(
                COMMAND ${CMAKE_COMMAND} --install . --prefix "${SOURCE_DIR}" --config Release
                WORKING_DIRECTORY "${SOURCE_DIR}/build"
                RESULT_VARIABLE cmakeResult
            )

            if(cmakeResult EQUAL "1")
                message(WARNING "Failed to install superfamiconv")
            else()
                find_program(CMAKE_SUPERFAMICONV_PROGRAM superfamiconv PATHS "${SOURCE_DIR}/bin")
            endif()
        endif()
    endif()
endif()

if(NOT CMAKE_SUPERFAMICONV_PROGRAM)
    message(WARNING "superfamiconv not found: Please set `-DCMAKE_SUPERFAMICONV_PROGRAM:FILEPATH=<path/to/bin/superfamiconv>`")
endif()

set(SUPERFAMICONV_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/../SuperFamiconv.cmake")

function(add_superfamiconv_graphics target)
    set(options
        PALETTE
        TILES
        MAP
        SPRITE_MODE
    )

    cmake_parse_arguments(ARGS "${options}" "" "" ${ARGN})

    if(NOT ARGS_PALETTE AND NOT ARGS_TILES AND NOT ARGS_MAP)
        message(FATAL_ERROR "add_superfamiconv_graphics requires PALETTE, TILES, or MAP")
    endif()

    set(commands)
    set(outputs)

    if(ARGS_PALETTE)
        set(paletteOutputs)
        foreach(input ${ARGS_UNPARSED_ARGUMENTS})
            get_filename_component(output "${input}" NAME_WE)
            list(APPEND paletteOutputs "${output}.palette")
        endforeach()
        list(APPEND outputs ${paletteOutputs})

        add_custom_command(
            OUTPUT ${paletteOutputs}
            DEPENDS ${ARGS_UNPARSED_ARGUMENTS}
            COMMAND "${CMAKE_COMMAND}" -DPALETTE=ON
                "-DPROGRAM=${CMAKE_SUPERFAMICONV_PROGRAM}"
                "-DPREFIX=${CMAKE_BINARY_DIR}/"
                -DSUFFIX=.palette
                "-DINPUTS=${ARGS_UNPARSED_ARGUMENTS}"
                -P "${SUPERFAMICONV_SCRIPT}"
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            VERBATIM
        )
    endif()

    if(ARGS_TILES)
        set(tilesOutputs)
        foreach(input ${ARGS_UNPARSED_ARGUMENTS})
            get_filename_component(output "${input}" NAME_WE)
            list(APPEND tilesOutputs "${output}.tiles")
        endforeach()
        list(APPEND outputs ${tilesOutputs})

        add_custom_command(
            OUTPUT ${tilesOutputs}
            DEPENDS ${ARGS_UNPARSED_ARGUMENTS} ${paletteOutputs}
            COMMAND "${CMAKE_COMMAND}" -DTILES=ON
                "-DPROGRAM=${CMAKE_SUPERFAMICONV_PROGRAM}"
                "-DPARAMS=$<IF:$<BOOL:${ARGS_SPRITE_MODE}>,--no-discard,${ARGS_TILES}>"
                "-DPREFIX=${CMAKE_BINARY_DIR}/"
                -DSUFFIX=.tiles
                "-DPREFIX_PALETTE=${CMAKE_BINARY_DIR}/"
                -DSUFFIX_PALETTE=.palette
                "-DINPUTS=${ARGS_UNPARSED_ARGUMENTS}"
                -P "${SUPERFAMICONV_SCRIPT}"
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            VERBATIM
        )
    endif()

    if(ARGS_MAP)
        set(mapOutputs)
        foreach(input ${ARGS_UNPARSED_ARGUMENTS})
            get_filename_component(output "${input}" NAME_WE)
            list(APPEND mapOutputs "${output}.map")
        endforeach()
        list(APPEND outputs ${mapOutputs})

        add_custom_command(
            OUTPUT ${mapOutputs}
            DEPENDS ${ARGS_UNPARSED_ARGUMENTS} ${tilesOutputs} ${paletteOutputs}
            COMMAND "${CMAKE_COMMAND}" -DMAP=ON
                "-DPROGRAM=${CMAKE_SUPERFAMICONV_PROGRAM}"
                "-DPREFIX=${CMAKE_BINARY_DIR}/"
                -DSUFFIX=.map
                "-DPREFIX_PALETTE=${CMAKE_BINARY_DIR}/"
                -DSUFFIX_PALETTE=.palette
                "-DPREFIX_TILES=${CMAKE_BINARY_DIR}/"
                -DSUFFIX_TILES=.tiles
                "-DINPUTS=${ARGS_UNPARSED_ARGUMENTS}"
                -P "${SUPERFAMICONV_SCRIPT}"
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            VERBATIM
        )
    endif()

    add_custom_target(${target} DEPENDS ${outputs})

    set(binaryOutput)
    foreach(output ${outputs})
        list(APPEND binaryOutput "${CMAKE_BINARY_DIR}/${output}")
    endforeach()

    set_target_properties(${target} PROPERTIES
        OUTPUT_FILES "${binaryOutput}"
        PALETTE_FILES "${paletteOutputs}"
        TILES_FILES "${tilesOutputs}"
        MAP_FILES "${mapOutputs}"
    )
endfunction()
