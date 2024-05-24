#===============================================================================
#
# Finds Gbt-Player and provides the `add_s3msplit_command` and `add_gbt_library` functions
#   If Gbt-Player is not available, it will be downloaded and compiled.
#   `add_s3msplit_command` splits s3m files into dedicated PSG and DMA s3m files.
#   `add_gbt_library` compiles s3m files into an object library to be linked.
#
# Files split with `add_s3msplit_command` will be marked GENERATED.
# The files are split relative to `CMAKE_CURRENT_BINARY_DIR`.
#
# Multiple Gbt-Player libraries may be linked together to produce a single soundbank.
#
# Gbt-Player libraries have the following properties:
#   `GBT_SOURCES` list of source paths relative to `CMAKE_CURRENT_SOURCE_DIR`.
#
# When passing sources directly to `add_gbt_library` the GENERATED flag will be checked
# this allows Gbt-Player libraries to be built with generated files (such as from `add_s3msplit_command`)
#
# Gbt-Player libraries also provide an INTERFACE link to libgbtplayer for convenience.
#
# Example splitting s3m file for both MaxMod and Gbt-Player:
#   ```cmake
#   add_s3msplit_command(template_combined.s3m
#        PSG music/template_combined_psg.s3m
#        DMA maxmod/template_combined_dma.s3m
#   )
#   add_maxmod_library(soundbank
#        maxmod/template_combined_dma.s3m
#   )
#   add_gbt_library(gbt
#        music/template_combined_psg.s3m
#   )
#   target_link_libraries(my_target PRIVATE soundbank gbt)
#   ```
#
# Split S3M command:
#   `add_s3msplit_command(<input-s3m> <PSG output-psg> <DMA output-dma>)`
#
# Add Gbt-Player library command:
#   `add_gbt_library(<target> <file-path>...)`
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

if(NOT Python_EXECUTABLE)
    find_package(Python COMPONENTS Interpreter REQUIRED)
endif()

function(add_s3msplit_command input)
    set(oneValueArgs PSG DMA)
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "" ${ARGN})

    get_filename_component(psgPath "${ARGS_PSG}" DIRECTORY)
    get_filename_component(dmaPath "${ARGS_DMA}" DIRECTORY)
    add_custom_command(OUTPUT "${ARGS_PSG}" "${ARGS_DMA}"
            DEPENDS "${input}"
            # Make output dirs
            COMMAND "${CMAKE_COMMAND}" -E make_directory "${psgPath}"
            COMMAND "${CMAKE_COMMAND}" -E make_directory "${dmaPath}"
            # Run s3msplit.py
            COMMAND "${Python_EXECUTABLE}" "${S3MSPLIT_PATH}"
                --input "${CMAKE_CURRENT_SOURCE_DIR}/${input}"
                --psg "${ARGS_PSG}"
                --dma "${ARGS_DMA}"
                > $<IF:$<BOOL:${CMAKE_HOST_WIN32}>,NUL,/dev/null> # Silence stdout
    )

    set_source_files_properties("${ARGS_PSG}" "${ARGS_DMA}" PROPERTIES GENERATED TRUE)
endfunction()

function(add_gbt_library target)
    set(gbtTargetDir "_gbt/${target}.dir")
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${gbtTargetDir}")
    set(sourcesEval $<TARGET_PROPERTY:${target},INTERFACE_SOURCES>)

    if(NOT C IN_LIST ENABLED_LANGUAGES)
        enable_language(C)
    endif()

    add_custom_command(OUTPUT "${gbtTargetDir}/${target}.o"
            DEPENDS $<PATH:ABSOLUTE_PATH,NORMALIZE,${sourcesEval},${CMAKE_CURRENT_SOURCE_DIR}>
            # Run s3m2gbt_multi.py
            COMMAND "${Python_EXECUTABLE}" "${S3M2GBT_MULTI_PATH}"
                --input $<PATH:ABSOLUTE_PATH,NORMALIZE,${sourcesEval},${CMAKE_CURRENT_SOURCE_DIR}>
                --name $<PATH:REMOVE_EXTENSION,$<PATH:GET_FILENAME,${sourcesEval}>>
                --output "${target}.c"
                > $<IF:$<BOOL:${CMAKE_HOST_WIN32}>,NUL,/dev/null> # Silence stdout
            # Create object file
            COMMAND "${CMAKE_C_COMPILER}" -c "${target}.c"
            # Remove byproducts
            COMMAND "${CMAKE_COMMAND}" -E rm -f "${target}.c"
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${gbtTargetDir}"
            COMMAND_EXPAND_LISTS
    )

    unset(sources)
    foreach(arg ${ARGN})
        if(IS_ABSOLUTE "${arg}" AND EXISTS "${arg}")
            list(APPEND sources "${arg}")
            continue()
        endif()

        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${arg}")
            list(APPEND sources "${arg}")
            continue()
        endif()

        get_source_file_property(isGenerated "${arg}" GENERATED)
        if(isGenerated)
            if(IS_ABSOLUTE "${arg}")
                list(APPEND sources "${arg}")
                continue()
            endif()

            list(APPEND sources "${CMAKE_CURRENT_BINARY_DIR}/${arg}")
            continue()
        endif()

        message(FATAL_ERROR "Cannot find source file: ${arg}")
    endforeach()

    add_library(${target} OBJECT IMPORTED)
    set_target_properties(${target} PROPERTIES
            IMPORTED_OBJECTS "${CMAKE_CURRENT_BINARY_DIR}/${gbtTargetDir}/${target}.o"
            GBT_SOURCES "${sources}"
    )
    target_sources(${target}
            INTERFACE "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<TARGET_PROPERTY:${target},GBT_SOURCES>,${CMAKE_CURRENT_SOURCE_DIR}>"
    )
    target_link_libraries(${target} INTERFACE gbtplayer)
endfunction()

include(FetchContent)
include(Mktemp)

mktemp(gbt_playerCMakeLists TMPDIR)
file(WRITE "${gbt_playerCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(gbt-player VERSION 4.4.1 LANGUAGES C)

add_library(gbtplayer STATIC gba/gbt_player/gbt_player.c)
target_include_directories(gbtplayer SYSTEM INTERFACE gba)
]=])

mktemp(gbt_playerMultiS3M2GBT TMPDIR)
file(WRITE "${gbt_playerMultiS3M2GBT}" [=[
if __name__ == '__main__':

    import argparse
    import sys
    import s3m2gbt
    import os

    parser = argparse.ArgumentParser(description='Convert multiple S3M files into GBT format binary file.')
    parser.add_argument('--input', nargs='+', default=None, required=True,
                        help='input files')
    parser.add_argument('--name', nargs='+', default=None, required=True,
                        help='output song names for each file')
    parser.add_argument('--output', default=None, required=True,
                        help='output C file for all songs')

    args = parser.parse_args()

    with open(args.output, "w") as outfile:
        for file_input, file_name in zip(args.input, args.name):
            try:
                s3m2gbt.convert_file(file_input, file_name, None, False)
                with open(file_name + '.c', 'r') as infile:
                    outfile.write(infile.read())
                os.remove(file_name + '.c')
            except s3m2gbt.RowConversionError as e:
                print('ERROR: ' + str(e))
                sys.exit(1)
            except s3m2gbt.S3MFormatError as e:
                print('ERROR: Invalid S3M file: ' + str(e))
                sys.exit(1)

    sys.exit(0)
]=])

FetchContent_Declare(gbt_player
        GIT_REPOSITORY "https://github.com/AntonioND/gbt-player.git"
        GIT_TAG "master"
        PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${gbt_playerCMakeLists}" "CMakeLists.txt"
            && "${CMAKE_COMMAND}" -E copy_if_different "${gbt_playerMultiS3M2GBT}" "gba/s3m2gbt/s3m2gbt_multi.py"
)
FetchContent_MakeAvailable(gbt_player)
file(REMOVE "${gbt_playerCMakeLists}")
file(REMOVE "${gbt_playerMultiS3M2GBT}")

if(NOT S3MSPLIT_PATH)
    find_file(S3MSPLIT_PATH s3msplit.py PATHS "${gbt_player_SOURCE_DIR}/gba/s3msplit")
endif()

if(NOT S3M2GBT_MULTI_PATH)
    find_file(S3M2GBT_MULTI_PATH s3m2gbt_multi.py PATHS "${gbt_player_SOURCE_DIR}/gba/s3m2gbt")
endif()
