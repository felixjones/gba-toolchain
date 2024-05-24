#===============================================================================
#
# Binary file concatenation utility
#   Concatenates a list of files into an output file
#
# Script usage:
#   `cmake -P /path/to/Bincat.cmake -- <output-file> [BOUNDARY <bytes>] <input-file>...]`
#
# CMake usage:
#   `bincat(<output-file> [BOUNDARY <bytes>] <input-file>...)`
#
# `BOUNDARY` sets the byte boundary that each input file should concatenate at.
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include("${CMAKE_CURRENT_LIST_DIR}/Mktemp.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Hexdecode.cmake")

function(bincat outfile)
    cmake_parse_arguments(ARGS "" "BOUNDARY" "" ${ARGN})

    # outfile will act as an accumulator
    execute_process(
            COMMAND "${CMAKE_COMMAND}" -E touch "${outfile}"
    )

    # Check boundary
    if(NOT ARGS_BOUNDARY)
        set(ARGS_BOUNDARY 1)
    endif()
    math(EXPR boundary "${ARGS_BOUNDARY}")
    if(boundary LESS_EQUAL 1)
        # Just need to cat into output
        execute_process(
                COMMAND "${CMAKE_COMMAND}" -E cat "${outfile}" ${ARGS_UNPARSED_ARGUMENTS}
                OUTPUT_FILE "${outfile}"
        )
        return()
    endif()

    foreach(file ${ARGS_UNPARSED_ARGUMENTS})
        # Calculate padding length
        file(SIZE "${outfile}" filesize)

        # Pad output
        math(EXPR paddingLength "${filesize} % ${boundary}")
        if(paddingLength)
            math(EXPR paddingLength "${boundary} - ${paddingLength}")

            # Write padding bytes
            string(REPEAT 00 ${paddingLength} paddingHexes)
            mktemp(tmphex)
            hexdecode("${tmphex}" "${paddingHexes}")

            # Concat padding bytes
            mktemp(tmppad)
            execute_process(
                    COMMAND "${CMAKE_COMMAND}" -E cat "${outfile}" "${tmphex}"
                    OUTPUT_FILE "${tmppad}"
            )
            file(REMOVE "${tmphex}")
            file(REMOVE "${outfile}")
            file(RENAME "${tmppad}" "${outfile}")
        endif()

        # Append file
        mktemp(tmpcat)
        execute_process(
                COMMAND "${CMAKE_COMMAND}" -E cat "${outfile}" "${file}"
                OUTPUT_FILE "${tmpcat}"
        )
        file(REMOVE "${outfile}")
        file(RENAME "${tmpcat}" "${outfile}")
    endforeach()
endfunction()

if(CMAKE_SCRIPT_MODE_FILE STREQUAL CMAKE_CURRENT_LIST_FILE)
    # Collect arguments past -- into SCRIPT_ARGN
    foreach(ii RANGE ${CMAKE_ARGC})
        if(${ii} EQUAL ${CMAKE_ARGC})
            break()
        elseif("${CMAKE_ARGV${ii}}" STREQUAL --)
            set(start ${ii})
        elseif(DEFINED start)
            list(APPEND SCRIPT_ARGN "${CMAKE_ARGV${ii}}")
        endif()
    endforeach()
    unset(start)
    unset(CMAKE_SCRIPT_MODE_FILE) # Enable nested include()

    # Forward script args to function
    bincat(${SCRIPT_ARGN})
else()
    set(BINCAT_PATH "${CMAKE_CURRENT_LIST_FILE}")
endif()
