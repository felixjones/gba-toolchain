#===============================================================================
#
# Finds Superfamiconv and provides the `add_superfamiconv_library` function
#   If Superfamiconv is not available, it will be downloaded and compiled.
#   `add_superfamiconv_library` compiles source images into an object library to be linked.
#
# Superfamiconv libraries have the following properties:
#   `SUPERFAMICONV_PALETTE_FLAGS` "${sfcPaletteFlags}" raw string flags sent to Superfamiconv palette.
#   `SUPERFAMICONV_TILES_FLAGS` "${sfcTilesFlags}" raw string flags sent to Superfamiconv tiles.
#   `SUPERFAMICONV_MAP_FLAGS` "${sfcMapFlags}" raw string flags sent to Superfamiconv map.
#   `SUPERFAMICONV_SOURCES` list of source paths relative to `CMAKE_CURRENT_SOURCE_DIR`.
#
# Superfamiconv libraries will generate a header file for convenience.
#
# Example:
#   ```cmake
#   add_superfamiconv_library(my_sprite PALETTE TILES
#       PALETTE_SPRITE_MODE
#       TILES_SPRITE_MODE
#       path/to/sprite.png
#   )
#   target_link_libraries(my_target PRIVATE my_sprite)
#   ```
#
# Add Superfamiconv library command:
#   ```cmake
#   add_superfamiconv_library(<target> [PALETTE] [TILES] [MAP]
#       [PALETTE_SPRITE_MODE]
#       [PALETTE_COUNT <integer>]
#       [PALETTE_COLORS <integer>]
#       [PALETTE_COLOR_ZERO <hex-code>]
#       [TILES_NO_DISCARD]
#       [TILES_NO_FLIP]
#       [TILES_SPRITE_MODE]
#       [TILES_BPP <integer>]
#       [TILES_MAX <integer>]
#       [MAP_NO_FLIP]
#       [MAP_COLUMN_ORDER]
#       [MAP_BPP <integer>]
#       [MAP_TILE_BASE <integer>]
#       [MAP_PALETTE_BASE <integer>]
#       [MAP_WIDTH <integer>]
#       [MAP_HEIGHT <integer>]
#       [MAP_SPLIT_WIDTH <tiles>]
#       [MAP_SPLIT_HEIGHT <tiles>]
#       <file-path>...
#   )
#   ```
#
# `PALETTE` forces palette generation.
# `TILES` forces tileset generation.
# `MAP` forces tilemap generation.
# `PALETTE_SPRITE_MODE` Apply sprite output settings.
# `PALETTE_COUNT` Number of subpalettes.
# `PALETTE_COLORS` Colors per subpalette.
# `PALETTE_COLOR_ZERO` Set color #0.
# `TILES_NO_DISCARD` Don't discard redundant tiles.
# `TILES_NO_FLIP` Don't discard using tile flipping.
# `TILES_SPRITE_MODE` Apply sprite output settings.
# `TILES_BPP` Bits per pixel.
# `TILES_MAX` Maximum number of tiles.
# `MAP_NO_FLIP` Don't use flipped tiles.
# `MAP_COLUMN_ORDER` Output data in column-major order.
# `MAP_BPP` Bits per pixel.
# `MAP_TILE_BASE` Tile base offset for map data.
# `MAP_PALETTE_BASE` Palette base offset for map data.
# `MAP_WIDTH` Map width (in tiles).
# `MAP_HEIGHT` Map height (in tiles).
# `MAP_SPLIT_WIDTH` Split output into columns of <tiles> width.
# `MAP_SPLIT_HEIGHT` Split output into rows of <tiles> height.
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

function(add_superfamiconv_library target)
    set(sfcTargetDir "_superfamiconv/${target}.dir")
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${sfcTargetDir}")
    set(sourcesEval $<TARGET_PROPERTY:${target},INTERFACE_SOURCES>)

    __sfc_palette_args()
    __sfc_tiles_args()
    __sfc_map_args()

    set(options ${paletteOptions} ${tilesOptions} ${mapOptions})
    set(oneValueArgs ${paletteOneValueArgs} ${tilesOneValueArgs} ${mapOneValueArgs})
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "" ${ARGN})

    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${sfcTargetDir}/${target}.cmake" [=[
foreach(ii RANGE ${CMAKE_ARGC})
    if(${ii} EQUAL ${CMAKE_ARGC})
        break()
    elseif("${CMAKE_ARGV${ii}}" STREQUAL --)
        set(start ${ii})
    elseif(DEFINED start)
        list(APPEND ARGN "${CMAKE_ARGV${ii}}")
    endif()
endforeach()
unset(start)

set(multiValueArgs PALETTE_FLAGS TILES_FLAGS MAP_FLAGS SOURCES)
cmake_parse_arguments(ARGS "" "" "${multiValueArgs}" ${ARGN})

foreach(arg ${ARGS_SOURCES})
    get_filename_component(name "${arg}" NAME_WE)

    if(ARGS_PALETTE_FLAGS)
        list(REMOVE_ITEM ARGS_PALETTE_FLAGS palette)
        execute_process(
            COMMAND "${SUPERFAMICONV_PATH}" palette --mode gba --in-image "${arg}"
                ${ARGS_PALETTE_FLAGS}
                --out-data "${name}Pal.bin"
        )
    endif()

    if(ARGS_TILES_FLAGS)
        list(REMOVE_ITEM ARGS_TILES_FLAGS tiles)
        execute_process(
            COMMAND "${SUPERFAMICONV_PATH}" tiles --mode gba --in-image "${arg}"
                ${ARGS_TILES_FLAGS}
                --in-palette "${name}Pal.bin"
                --out-data "${name}Tiles.bin"
        )
    endif()

    if(ARGS_MAP_FLAGS)
        list(REMOVE_ITEM ARGS_MAP_FLAGS map)
        execute_process(
            COMMAND "${SUPERFAMICONV_PATH}" map --mode gba --in-image "${arg}"
                ${ARGS_MAP_FLAGS}
                --in-palette "${name}Pal.bin"
                --in-tiles "${name}Tiles.bin"
                --out-data "${name}Map.bin"
        )
    endif()

    if(NOT ARGS_PALETTE_FLAGS AND NOT ARGS_TILES_FLAGS AND NOT ARGS_MAP_FLAGS)
        execute_process(
            COMMAND "${SUPERFAMICONV_PATH}" --mode gba --in-image "${arg}"
                --out-tiles "${name}Tiles.bin"
                --out-map "${name}Map.bin"
                --out-palette "${name}Pal.bin"
        )
    endif()
endforeach()
]=])

    add_custom_command(OUTPUT "${sfcTargetDir}/${target}.o" "${sfcTargetDir}/${target}.h"
            DEPFILE "${sfcTargetDir}/${target}.d"
            # Create depfile
            COMMAND "${CMAKE_COMMAND}" -P "${DEPFILE_PATH}" -- "${target}.d"
                TARGETS "${sfcTargetDir}/${target}.o" "${sfcTargetDir}/${target}.h"
                DEPENDENCIES
                    $<PATH:ABSOLUTE_PATH,NORMALIZE,${sourcesEval},${CMAKE_CURRENT_SOURCE_DIR}>
                    "${CMAKE_CURRENT_BINARY_DIR}/${sfcTargetDir}/${target}.cmake"
            # Run Superfamiconv script
            COMMAND "${CMAKE_COMMAND}" -D "SUPERFAMICONV_PATH=\"${SUPERFAMICONV_PATH}\"" -P "${target}.cmake" --
                PALETTE_FLAGS $<TARGET_PROPERTY:${target},SUPERFAMICONV_PALETTE_FLAGS>
                TILES_FLAGS $<TARGET_PROPERTY:${target},SUPERFAMICONV_TILES_FLAGS>
                MAP_FLAGS $<TARGET_PROPERTY:${target},SUPERFAMICONV_MAP_FLAGS>
                SOURCES ${sourcesEval}
            # Create object file
            COMMAND "${CMAKE_COMMAND}" -D "CMAKE_LINKER=\"${CMAKE_LINKER}\"" -D "CMAKE_OBJCOPY=\"${CMAKE_OBJCOPY}\""
                -P "${BIN2O_PATH}" -- "${target}.o" HEADER "${target}.h" SUFFIX_END End SUFFIX_SIZE Len NAME_WE ERROR_QUIET
                    $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Tiles.bin$<SEMICOLON>>Tiles.bin
                    $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Map.bin$<SEMICOLON>>Map.bin
                    $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Pal.bin$<SEMICOLON>>Pal.bin
            # Remove byproducts
            COMMAND "${CMAKE_COMMAND}" -E rm -f
                $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Tiles.bin$<SEMICOLON>>Tiles.bin
                $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Map.bin$<SEMICOLON>>Map.bin
                $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Pal.bin$<SEMICOLON>>Pal.bin
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${sfcTargetDir}"
            COMMAND_EXPAND_LISTS
    )

    macro(__sfc_build_args output)
        foreach(option ${ARGN})
            if(NOT ARGS_${option})
                continue()
            endif()

            if(${option}_KEYS)  # Keyword arg
                unset(sfcMultiArgs)
                foreach(arg ${ARGS_${option}})
                    if(NOT ${arg} IN_LIST ${option}_KEYS)
                        message(WARNING "Unknown key \"${arg}\" for \"${option}\"")
                        continue()
                    endif()

                    list(APPEND sfcMultiArgs ${${option}_VALUE_${arg}})
                endforeach()

                list(APPEND ${output} ${${option}} ${sfcMultiArgs})
            elseif(${option}_ARG)  # One value arg
                list(APPEND ${output} ${${option}} ${ARGS_${option}})
            else()  # Flag
                list(APPEND ${output} ${${option}})
            endif()
        endforeach()
    endmacro()

    __sfc_build_args(sfcPaletteFlags ${paletteOptions} ${paletteOneValueArgs})
    __sfc_build_args(sfcTilesFlags ${tilesOptions} ${tilesOneValueArgs})
    __sfc_build_args(sfcMapFlags ${mapOptions} ${mapOneValueArgs})

    add_library(${target} OBJECT IMPORTED)
    set_target_properties(${target} PROPERTIES
            IMPORTED_OBJECTS "${CMAKE_CURRENT_BINARY_DIR}/${sfcTargetDir}/${target}.o"
            SUPERFAMICONV_PALETTE_FLAGS "${sfcPaletteFlags}"
            SUPERFAMICONV_TILES_FLAGS "${sfcTilesFlags}"
            SUPERFAMICONV_MAP_FLAGS "${sfcMapFlags}"
            SUPERFAMICONV_SOURCES "${ARGS_UNPARSED_ARGUMENTS}"
    )
    target_sources(${target}
            INTERFACE "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<TARGET_PROPERTY:${target},SUPERFAMICONV_SOURCES>,${CMAKE_CURRENT_SOURCE_DIR}>"
    )
    target_include_directories(${target} INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/${sfcTargetDir}")
endfunction()

macro(__sfc_palette_args)
    set(PALETTE "palette")
    set(PALETTE_COUNT "-P")
        set(PALETTE_COUNT_ARG ON)
    set(PALETTE_COLORS "-C")
        set(PALETTE_COLORS_ARG ON)
    set(PALETTE_SPRITE_MODE "-S")
    set(PALETTE_COLOR_ZERO "-0")
        set(PALETTE_COLOR_ZERO_ARG ON)

    set(paletteOptions
            PALETTE
            PALETTE_SPRITE_MODE
    )
    set(paletteOneValueArgs
            PALETTE_COUNT
            PALETTE_COLORS
            PALETTE_COLOR_ZERO
    )
endmacro()

macro(__sfc_tiles_args)
    set(TILES "tiles")
    set(TILES_BPP "-B")
        set(TILES_BPP_ARG ON)
    set(TILES_NO_DISCARD "-D")
    set(TILES_NO_FLIP "-F")
    set(TILES_SPRITE_MODE "-S")
    set(TILES_MAX "-T")
        set(TILES_MAX_ARG ON)

    set(tilesOptions
            TILES
            TILES_NO_DISCARD
            TILES_NO_FLIP
            TILES_SPRITE_MODE
    )
    set(tilesOneValueArgs
            TILES_BPP
            TILES_MAX
    )
endmacro()

macro(__sfc_map_args)
    set(MAP "map")
    set(MAP_BPP "-B")
        set(MAP_BPP_ARG ON)
    set(MAP_NO_FLIP "-F")
    set(MAP_TILE_BASE "-T")
        set(MAP_TILE_BASE_ARG ON)
    set(MAP_PALETTE_BASE "-T")
        set(MAP_PALETTE_BASE_ARG ON)
    set(MAP_WIDTH "--map-width")
        set(MAP_WIDTH_ARG ON)
    set(MAP_HEIGHT "--map-height")
        set(MAP_HEIGHT_ARG ON)
    set(MAP_SPLIT_WIDTH "--split-width")
        set(MAP_SPLIT_WIDTH_ARG ON)
    set(MAP_SPLIT_HEIGHT "--split-height")
        set(MAP_SPLIT_HEIGHT_ARG ON)
    set(MAP_COLUMN_ORDER "--column-order")

    set(mapOptions
            MAP
            MAP_NO_FLIP
            MAP_COLUMN_ORDER
    )
    set(mapOneValueArgs
            MAP_BPP
            MAP_TILE_BASE
            MAP_PALETTE_BASE
            MAP_WIDTH
            MAP_HEIGHT
            MAP_SPLIT_WIDTH
            MAP_SPLIT_HEIGHT
    )
endmacro()

find_program(SUPERFAMICONV_PATH superfamiconv superfamiconv.exe
        PATHS ${devkitARM} "${SUPERFAMICONV_DIR}" $ENV{HOME}
        PATH_SUFFIXES "bin" "tools/bin"
)

if(SUPERFAMICONV_PATH)
    return()
endif()

include(FetchContent)
include(ProcessorCount)

FetchContent_Declare(superfamiconv
        GIT_REPOSITORY "https://github.com/Optiroc/SuperFamiconv.git"
        GIT_TAG "main"
)

FetchContent_GetProperties(superfamiconv)
if(NOT superfamiconv_POPULATED)
    FetchContent_Populate(superfamiconv)

    if(CMAKE_C_COMPILER_LAUNCHER)
        list(APPEND cmakeFlags -D CMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER})
    endif()
    if(CMAKE_CXX_COMPILER_LAUNCHER)
        list(APPEND cmakeFlags -D CMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER})
    endif()
    ProcessorCount(nproc)
    math(EXPR nproc "${nproc} - 1")

    execute_process(COMMAND "${CMAKE_COMMAND}" -S "${superfamiconv_SOURCE_DIR}" -B "${superfamiconv_BINARY_DIR}" -G "${CMAKE_GENERATOR}" -D CMAKE_CXX_FLAGS="-Wno-return-type" ${cmakeFlags})  # Configure
    execute_process(COMMAND "${CMAKE_COMMAND}" --build "${superfamiconv_BINARY_DIR}" --parallel ${nproc})  # Build
    find_program(SUPERFAMICONV_PATH superfamiconv superfamiconv.exe PATHS "${superfamiconv_BINARY_DIR}")
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
        file(INSTALL "${SUPERFAMICONV_PATH}" DESTINATION "$ENV{HOME}/bin")  # Install
    endif()
endif()
