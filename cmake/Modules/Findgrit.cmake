#===============================================================================
#
# Finds grit and provides the `add_grit_library` function
#   If grit is not available, it will be downloaded and compiled.
#   `add_grit_library` compiles source images into an object library to be linked.
#
# grit libraries have the following properties:
#   `GRIT_FLAGS` raw string flags sent to grit.
#   `GRIT_FLAGS_FILE` path to a .grit additional flags file.
#   `GRIT_TILESET_FILE` path to a tileset file.
#   `GRIT_SOURCES` list of source paths relative to `CMAKE_CURRENT_SOURCE_DIR`.
#
# grit libraries will generate a header file for convenience.
#
# Example:
#   ```cmake
#   add_grit_library(my_sprite
#       GRAPHICS_BIT_DEPTH 4
#       path/to/sprite.png
#   )
#   target_link_libraries(my_target PRIVATE my_sprite)
#   ```
#
# Add grit library command:
#   ```cmake
#   add_grit_library(<target> [PALETTE_SHARED] [GRAPHICS_SHARED] [FLAGS <flags-string>] [FLAGS_FILE <flags-path>] [TILESET_FILE <tileset-path>]
#       [PALETTE|NO_PALETTE]
#       [PALETTE_COMPRESSION <OFF|LZ77|HUFF|RLE|FAKE>]
#       [PALETTE_RANGE_START <integer>]
#       [PALETTE_RANGE_END <integer>]
#       [PALETTE_COUNT <integer>]
#       [PALETTE_TRANSPARENT_INDEX <integer>]
#       [GRAPHICS|NO_GRAPHICS]
#       [GRAPHICS_COMPRESSION <OFF|LZ77|HUFF|RLE|FAKE>]
#       [GRAPHICS_PIXEL_OFFSET <integer>]
#       [GRAPHICS_FORMAT <BITMAP|TILE>]
#       [GRAPHICS_BIT_DEPTH <integer>]
#       [GRAPHICS_TRANSPARENT_COLOR <hex-code>]
#       [AREA_LEFT <integer>]
#       [AREA_RIGHT <integer>]
#       [AREA_WIDTH <integer>]
#       [AREA_TOP <integer>]
#       [AREA_BOTTOM <integer>]
#       [AREA_HEIGHT <integer>]
#       [MAP|NO_MAP]
#       [MAP_COMPRESSION <OFF|LZ77|HUFF|RLE|FAKE>]
#       [<MAP_TILE_REDUCTION <TILES|PALETTES|FLIPPED>...>|MAP_NO_TILE_REDUCTION]
#       [MAP_LAYOUT <REGULAR_FLAT|REGULAR_SBB|AFFINE>]
#       [METATILE_HEIGHT <integer>]
#       [METATILE_WIDTH <integer>]
#       [METATILE_REDUCTION]
#       <file-path>...
#   )
#   ```
#
# `PALETTE_SHARED` write palettes to shared file. Requires multiple inputs.
# `GRAPHICS_SHARED` write graphics to shared file. Requires multiple inputs.
# `FLAGS` raw flags passed to grit.
# `FLAGS_FILE` .grit flags file with additional flags.
# `TILESET_FILE` tileset file.
# `PALETTE`, `NO_PALETTE` include/exclude palette generation.
# `PALETTE_COMPRESSION` palette compression format.
#   `OFF` no compression.
#   `LZ77` LZ77 compression.
#   `HUFF` Huffman compression.
#   `RLE` run-length-encoding compression.
#   `FAKE` no compression, but use compression compatible header.
# `PALETTE_RANGE_START` index of first palette entry.
# `PALETTE_RANGE_END` index of last palette entry.
# `PALETTE_COUNT` number of palette entries. Cannot be used with `PALETTE_RANGE_END`.
# `PALETTE_TRANSPARENT_INDEX` palette entry to use as transparency.
# `GRAPHICS`, `NO_GRAPHICS` include/exclude tile graphics generation.
# `GRAPHICS_COMPRESSION` tile graphics compression format.
#   `OFF` no compression.
#   `LZ77` LZ77 compression.
#   `HUFF` Huffman compression.
#   `RLE` run-length-encoding compression.
#   `FAKE` no compression, but use compression compatible header.
# `GRAPHICS_PIXEL_OFFSET` number of pixels to offset the source image.
# `GRAPHICS_FORMAT` type of output image.
#   `BITMAP` direct bitmap image output.
#   `TILE` tile-map sprite or background output.
# `GRAPHICS_BIT_DEPTH` bit depth (1, 2, 4, 8, 16).
# `GRAPHICS_TRANSPARENT_COLOR` hex color to use as transparency.
# `AREA_LEFT` source image left margin.
# `AREA_RIGHT` source image right margin.
# `AREA_WIDTH` source image width. Cannot be used with `AREA_RIGHT`.
# `AREA_TOP` source image top margin.
# `AREA_BOTTOM` source image bottom margin.
# `AREA_HEIGHT` source image height. Cannot be used with `AREA_BOTTOM`.
# `MAP`, `NO_MAP` include/exclude screen map generation.
# `MAP_COMPRESSION` tile map compression format.
#   `OFF` no compression.
#   `LZ77` LZ77 compression.
#   `HUFF` Huffman compression.
#   `RLE` run-length-encoding compression.
#   `FAKE` no compression, but use compression compatible header.
# `MAP_TILE_REDUCTION`, `MAP_NO_TILE_REDUCTION` screen entry tile reduction.
#   `TILES` reduce common tile graphics.
#   `PALETTES` reduce shared palettes.
#   `FLIPPED` reduce flipped tiles.
# `MAP_LAYOUT` screen map layout.
#   `REGULAR_FLAT` regular flat map.
#   `REGULAR_SBB` regular screen base block map.
#   `AFFINE` affine tile-map (mode 1, 2).
# `METATILE_HEIGHT` combine N vertical screen entries into meta tiles.
# `METATILE_WIDTH` combine N horizontal screen entries into meta tiles.
# `METATILE_REDUCTION` reduce meta tiles (can only reduce by palettes).
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include(Bin2o)
include(Depfile)
include(FileRename)

#TODO: add_grit_command

function(add_grit_library target)
    set(gritTargetDir "_grit/${target}.dir")
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${gritTargetDir}")
    set(sourcesEval $<TARGET_PROPERTY:${target},INTERFACE_SOURCES>)
    set(flagsFileEval $<TARGET_PROPERTY:${target},GRIT_FLAGS_FILE>)
    set(tilesetFileEval $<TARGET_PROPERTY:${target},GRIT_TILESET_FILE>)

    __grit_palette_args()
    __grit_graphics_args()
    __grit_map_args()
    __grit_meta_args()

    set(options ${paletteOptions} ${graphicsOptions} ${mapOptions} ${metaOptions}
            PALETTE_SHARED
            GRAPHICS_SHARED
    )
    set(oneValueArgs ${paletteOneValueArgs} ${graphicsOneValueArgs} ${mapOneValueArgs} ${metaOneValueArgs}
            FLAGS
            FLAGS_FILE
            TILESET_FILE
    )
    set(multiValueArgs ${mapMultiValueArgs})
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(ARGS_PALETTE_SHARED)
        list(APPEND sharedFlags -pS)
    endif()
    if(ARGS_GRAPHICS_SHARED)
        list(APPEND sharedFlags -gS)
    endif()
    if(sharedFlags)
        list(APPEND sharedFlags -O${target})
    endif()

    add_custom_command(OUTPUT "${gritTargetDir}/${target}.o" "${gritTargetDir}/${target}.h"
            DEPENDS "${sourcesEval}"
            # Run grit
            COMMAND "${GRIT_PATH}" $<PATH:ABSOLUTE_PATH,NORMALIZE,${sourcesEval},${CMAKE_CURRENT_SOURCE_DIR}> -fh! -ftb
                $<TARGET_PROPERTY:${target},GRIT_FLAGS>
                $<$<BOOL:${flagsFileEval}>:-ff$<PATH:ABSOLUTE_PATH,NORMALIZE,${flagsFileEval},${CMAKE_CURRENT_SOURCE_DIR}>>
                $<$<BOOL:${tilesetFileEval}>:-fx$<PATH:ABSOLUTE_PATH,NORMALIZE,${tilesetFileEval},${CMAKE_CURRENT_SOURCE_DIR}>>
                "$<$<BOOL:${sharedFlags}>:${sharedFlags}>"
            # Rename byproducts
            COMMAND "${CMAKE_COMMAND}" -P "${FILE_RENAME_PATH}" -- "[.]img[.]bin$$" "Tiles.bin" ERROR_QUIET $<PATH:REPLACE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>,img.bin>
            COMMAND "${CMAKE_COMMAND}" -P "${FILE_RENAME_PATH}" -- "[.]map[.]bin$$" "Map.bin" ERROR_QUIET $<PATH:REPLACE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>,map.bin>
            COMMAND "${CMAKE_COMMAND}" -P "${FILE_RENAME_PATH}" -- "[.]pal[.]bin$$" "Pal.bin" ERROR_QUIET $<PATH:REPLACE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>,pal.bin>
            # Rename shared output (if any)
            COMMAND "${CMAKE_COMMAND}" -P "${FILE_RENAME_PATH}" -- "[.]img[.]bin$$" "Tiles.bin" ERROR_QUIET "${target}.img.bin"
            COMMAND "${CMAKE_COMMAND}" -P "${FILE_RENAME_PATH}" -- "[.]pal[.]bin$$" "Pal.bin" ERROR_QUIET "${target}.pal.bin"
            # Create object file
            COMMAND ${BIN2O_COMMAND} "${target}.o" HEADER "${target}.h" SUFFIX_END End SUFFIX_SIZE Len NAME_WE ERROR_IGNORE
                    $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Tiles.bin$<SEMICOLON>>Tiles.bin
                    $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Map.bin$<SEMICOLON>>Map.bin
                    $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Pal.bin$<SEMICOLON>>Pal.bin
                    $<$<BOOL:${ARGS_PALETTE_SHARED}>:"${target}Pal.bin">
                    $<$<BOOL:${ARGS_GRAPHICS_SHARED}>:"${target}Tiles.bin">
            # Remove byproducts
            COMMAND "${CMAKE_COMMAND}" -E rm -f
                $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Tiles.bin$<SEMICOLON>>Tiles.bin
                $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Map.bin$<SEMICOLON>>Map.bin
                $<JOIN:$<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>,Pal.bin$<SEMICOLON>>Pal.bin
                $<$<BOOL:${ARGS_PALETTE_SHARED}>:"${target}Pal.bin">
                $<$<BOOL:${ARGS_GRAPHICS_SHARED}>:"${target}Tiles.bin">
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${gritTargetDir}"
            COMMAND_EXPAND_LISTS
    )

    if(ARGS_FLAGS)
        separate_arguments(gritFlags NATIVE_COMMAND "${ARGS_FLAGS}")
    endif()

    foreach(option ${paletteOptions} ${paletteOneValueArgs} ${graphicsOptions} ${graphicsOneValueArgs} ${mapOptions} ${mapOneValueArgs} ${mapMultiValueArgs} ${metaOptions} ${metaOneValueArgs})
        if(NOT ARGS_${option})
            continue()
        endif()

        if(${option}_KEYS)  # Keyword arg
            unset(gritMultiArgs)
            foreach(arg ${ARGS_${option}})
                if(NOT ${arg} IN_LIST ${option}_KEYS)
                    message(WARNING "Unknown key \"${arg}\" for \"${option}\"")
                    continue()
                endif()

                string(APPEND gritMultiArgs ${${option}_VALUE_${arg}})
            endforeach()

            list(APPEND gritFlags "${${option}}${gritMultiArgs}")
        elseif(${option}_ARG)  # One value arg
            list(APPEND gritFlags "${${option}}${ARGS_${option}}")
        else()  # Flag
            list(APPEND gritFlags "${${option}}")
        endif()
    endforeach()

    add_library(${target} OBJECT IMPORTED)
    set_target_properties(${target} PROPERTIES
            IMPORTED_OBJECTS "${CMAKE_CURRENT_BINARY_DIR}/${gritTargetDir}/${target}.o"
            GRIT_FLAGS "${gritFlags}"
            GRIT_FLAGS_FILE "${ARGS_FLAGS_FILE}"
            GRIT_TILESET_FILE "${ARGS_TILESET_FILE}"
            GRIT_SOURCES "${ARGS_UNPARSED_ARGUMENTS}"
    )
    target_sources(${target}
            INTERFACE "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<TARGET_PROPERTY:${target},GRIT_SOURCES>,${CMAKE_CURRENT_SOURCE_DIR}>"
    )
    target_include_directories(${target} INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/${gritTargetDir}")
endfunction()

macro(__grit_palette_args)
    set(PALETTE "-p")
    set(NO_PALETTE "-p!")
    set(PALETTE_COMPRESSION "-pz")
        set(PALETTE_COMPRESSION_KEYS OFF LZ77 HUFF RLE FAKE)
            set(PALETTE_COMPRESSION_VALUE_OFF "!")
            set(PALETTE_COMPRESSION_VALUE_LZ77 "l")
            set(PALETTE_COMPRESSION_VALUE_HUFF "h")
            set(PALETTE_COMPRESSION_VALUE_RLE "r")
            set(PALETTE_COMPRESSION_VALUE_FAKE "0")
    set(PALETTE_RANGE_START "-ps")
        set(PALETTE_RANGE_START_ARG ON)
    set(PALETTE_RANGE_END "-pe")
        set(PALETTE_RANGE_END_ARG ON)
    set(PALETTE_COUNT "-pn")
        set(PALETTE_COUNT_ARG ON)
    set(PALETTE_TRANSPARENT_INDEX "-pT")
        set(PALETTE_TRANSPARENT_INDEX_ARG ON)

    set(paletteOptions
            PALETTE
            NO_PALETTE
    )
    set(paletteOneValueArgs
            PALETTE_COMPRESSION
            PALETTE_RANGE_START
            PALETTE_RANGE_END
            PALETTE_COUNT
            PALETTE_TRANSPARENT_INDEX
    )
endmacro()

macro(__grit_graphics_args)
    set(GRAPHICS "-g")
    set(NO_GRAPHICS "-g!")
    set(GRAPHICS_COMPRESSION "-gz")
        set(GRAPHICS_COMPRESSION_KEYS OFF LZ77 HUFF RLE FAKE)
            set(GRAPHICS_COMPRESSION_VALUE_OFF "!")
            set(GRAPHICS_COMPRESSION_VALUE_LZ77 "l")
            set(GRAPHICS_COMPRESSION_VALUE_HUFF "h")
            set(GRAPHICS_COMPRESSION_VALUE_RLE "r")
            set(GRAPHICS_COMPRESSION_VALUE_FAKE "0")
    set(GRAPHICS_PIXEL_OFFSET "-ga")
        set(GRAPHICS_PIXEL_OFFSET_ARG ON)
    set(GRAPHICS_FORMAT "-g")
        set(GRAPHICS_FORMAT_KEYS BITMAP TILE)
            set(GRAPHICS_FORMAT_VALUE_BITMAP "b")
            set(GRAPHICS_FORMAT_VALUE_TILE "t")
    set(GRAPHICS_BIT_DEPTH "-gB")
        set(GRAPHICS_BIT_DEPTH_ARG ON)
    set(GRAPHICS_TRANSPARENT_COLOR "-gT")
        set(GRAPHICS_TRANSPARENT_COLOR_ARG ON)

    set(AREA_LEFT "-al")
        set(AREA_LEFT_ARG ON)
    set(AREA_RIGHT "-ar")
        set(AREA_RIGHT_ARG ON)
    set(AREA_WIDTH "-aw")
        set(AREA_WIDTH_ARG ON)
    set(AREA_TOP "-at")
        set(AREA_TOP_ARG ON)
    set(AREA_BOTTOM "-ab")
        set(AREA_BOTTOM_ARG ON)
    set(AREA_HEIGHT "-ah")
        set(AREA_HEIGHT_ARG ON)

    set(graphicsOptions
            GRAPHICS
            NO_GRAPHICS
    )
    set(graphicsOneValueArgs
            GRAPHICS_COMPRESSION
            GRAPHICS_PIXEL_OFFSET
            GRAPHICS_FORMAT
            GRAPHICS_BIT_DEPTH
            GRAPHICS_TRANSPARENT_COLOR
            AREA_LEFT
            AREA_RIGHT
            AREA_WIDTH
            AREA_TOP
            AREA_BOTTOM
            AREA_HEIGHT
    )
endmacro()

macro(__grit_map_args)
    set(MAP "-m")
    set(NO_MAP "-m!")
    set(MAP_COMPRESSION "-mz")
        set(MAP_COMPRESSION_KEYS OFF LZ77 HUFF RLE FAKE)
            set(MAP_COMPRESSION_VALUE_OFF "!")
            set(MAP_COMPRESSION_VALUE_LZ77 "l")
            set(MAP_COMPRESSION_VALUE_HUFF "h")
            set(MAP_COMPRESSION_VALUE_RLE "r")
            set(MAP_COMPRESSION_VALUE_FAKE "0")
    set(MAP_TILE_REDUCTION "-mR")
        set(MAP_TILE_REDUCTION_KEYS TILES PALETTES FLIPPED)
            set(MAP_TILE_REDUCTION_VALUE_TILES "t")
            set(MAP_TILE_REDUCTION_VALUE_PALETTES "p")
            set(MAP_TILE_REDUCTION_VALUE_FLIPPED "f")
    set(MAP_NO_TILE_REDUCTION "-mR!")
        set(MAP_NO_TILE_REDUCTION_ARG ON)
    set(MAP_LAYOUT "-mL")
        set(MAP_LAYOUT_KEYS REGULAR_FLAT REGULAR_SBB AFFINE)
            set(MAP_LAYOUT_VALUE_REGULAR_FLAT "f")
            set(MAP_LAYOUT_VALUE_REGULAR_SBB "s")
            set(MAP_LAYOUT_VALUE_AFFINE "a")

    set(mapOptions
            MAP
            NO_MAP
            MAP_NO_TILE_REDUCTION
    )
    set(mapOneValueArgs
            MAP_COMPRESSION
            MAP_LAYOUT
    )
    set(mapMultiValueArgs MAP_TILE_REDUCTION)
endmacro()

macro(__grit_meta_args)
    set(METATILE_HEIGHT "-Mh")
        set(METATILE_HEIGHT_ARG ON)
    set(METATILE_WIDTH "-Mw")
        set(METATILE_WIDTH_ARG ON)
    set(METATILE_REDUCTION "-MRp")

    set(metaOptions
            METATILE_REDUCTION
    )
    set(metaOneValueArgs
            METATILE_HEIGHT
            METATILE_WIDTH
    )
endmacro()

find_program(GRIT_PATH grit grit.exe
        PATHS ${devkitARM} "${GRIT_DIR}" $ENV{HOME}
        PATH_SUFFIXES "bin" "tools/bin"
)

if(GRIT_PATH)
    return()
endif()

include(FetchContent)
include(Mktemp)
include(ProcessorCount)

mktemp(gritCMakeLists TMPDIR)
file(WRITE "${gritCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(grit VERSION 0.9.2 LANGUAGES CXX)

include(FetchContent)

add_library(cldib STATIC
        cldib/cldib_adjust.cpp
        cldib/cldib_conv.cpp
        cldib/cldib_core.cpp
        cldib/cldib_tmap.cpp
        cldib/cldib_tools.cpp
        cldib/cldib_wu.cpp
)

find_library(FreeImage_LIB_PATH NAMES freeimage)
find_path(FreeImage_INCLUDE_PATH FreeImage.h)

if(FreeImage_LIB_PATH AND FreeImage_INCLUDE_PATH)
    target_link_libraries(cldib PUBLIC "${FreeImage_LIB_PATH}")
    target_include_directories(cldib PUBLIC cldib "${FreeImage_INCLUDE_PATH}")
else()
    FetchContent_Declare(FreeImage
            GIT_REPOSITORY "https://github.com/danoli3/FreeImage.git"
            GIT_TAG "master"
    )
    FetchContent_GetProperties(FreeImage)
    if(NOT FreeImage_POPULATED)
      FetchContent_Populate(FreeImage)
      add_subdirectory(${freeimage_SOURCE_DIR} ${freeimage_BINARY_DIR} EXCLUDE_FROM_ALL)
    endif()

    target_link_libraries(cldib PUBLIC FreeImage)
    target_include_directories(cldib PUBLIC cldib "${FreeImage_SOURCE_DIR}/Source")
endif()

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
target_link_libraries(grit PRIVATE libgrit $<$<NOT:$<BOOL:MSVC>>:m>)
install(TARGETS grit DESTINATION bin)
]=])

FetchContent_Declare(grit
        GIT_REPOSITORY "https://github.com/devkitPro/grit.git"
        GIT_TAG "master"
)

FetchContent_GetProperties(grit)
if(NOT grit_POPULATED)
    FetchContent_Populate(grit)
    execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${gritCMakeLists}" "${grit_SOURCE_DIR}/CMakeLists.txt")
    file(REMOVE "${gritCMakeLists}")

    if(CMAKE_C_COMPILER_LAUNCHER)
        list(APPEND cmakeFlags -D CMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER})
    endif()
    if(CMAKE_CXX_COMPILER_LAUNCHER)
        list(APPEND cmakeFlags -D CMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER})
    endif()
    ProcessorCount(nproc)
    math(EXPR nproc "${nproc} - 1")

    execute_process(COMMAND "${CMAKE_COMMAND}" -S "${grit_SOURCE_DIR}" -B "${grit_BINARY_DIR}" -G "${CMAKE_GENERATOR}" ${cmakeFlags})  # Configure
    execute_process(COMMAND "${CMAKE_COMMAND}" --build "${grit_BINARY_DIR}" --parallel ${nproc})  # Build
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
        execute_process(COMMAND "${CMAKE_COMMAND}" --install "${grit_BINARY_DIR}" --prefix $ENV{HOME})  # Install
    endif()

    find_program(GRIT_PATH grit grit.exe PATHS "${grit_BINARY_DIR}")
else()
    file(REMOVE "${gritCMakeLists}")
endif()
