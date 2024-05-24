#===============================================================================
#
# Hex to binary utility
#   Decodes a list of hex code inputs into a file
#
# Script usage:
#   `cmake -P /path/to/Hexdecode.cmake -- <output-file> <input-hex-string>...`
#
# CMake usage:
#   `hexdecode(<output-file> <input-hex-string>...)`
#
# `input-hex-string` must consist of only valid hexadecimal characters [0-9a-fA-F].
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include("${CMAKE_CURRENT_LIST_DIR}/IHex.cmake" OPTIONAL RESULT_VARIABLE IHEX_INCLUDED)
include("${CMAKE_CURRENT_LIST_DIR}/Mktemp.cmake" OPTIONAL RESULT_VARIABLE MKTEMP_INCLUDED)

function(hexdecode outfile)
    if(NOT ARGN)
        message(FATAL_ERROR "hexdecode requires at least 1 argument.")
    endif()

    # Join all hex lists
    string(JOIN "" hexes ${ARGN})

    # Decode hexes into outfile

    # Try if xxd is available
    find_program(XXD_EXECUTABLE NAMES xxd)
    if(XXD_EXECUTABLE)
        execute_process(
                COMMAND "${CMAKE_COMMAND}" -E echo_append "${hexes}"
                COMMAND "${XXD_EXECUTABLE}" --revert --ps
                OUTPUT_FILE "${outfile}"
        )
        return()
    endif()

    # Try if powershell is available
    find_program(POWERSHELL_EXECUTABLE NAMES powershell pwsh)
    if(POWERSHELL_EXECUTABLE)
        execute_process(
                COMMAND "${POWERSHELL_EXECUTABLE}" -Command "
        $hexString = '${hexes}';
            $byteArray = for ($i = 0; $i -lt $hexString.length; $i+=2) {
                [Convert]::ToByte($hexString.Substring($i, 2), 16)
            };
            [IO.File]::WriteAllBytes('${outfile}', $byteArray)
        "
        )
        return()
    endif()

    # Try if IHex and objcopy are available (SLOW!)
    find_program(OBJCOPY_EXECUTABLE NAMES objcopy)
    if(IHEX_INCLUDED AND MKTEMP_INCLUDED AND OBJCOPY_EXECUTABLE)
        ihex(outputHex RECORD_LENGTH 0xff ${hexes})
        mktemp(tmpfile)

        file(WRITE "${tmpfile}" "${outputHex}")
        execute_process(COMMAND "${OBJCOPY_EXECUTABLE}" -I ihex "${tmpfile}" -O binary "${outfile}")
        file(REMOVE "${tmpfile}")

        return()
    endif()

    message(FATAL_ERROR "Failed to decode hex: Missing dependencies.")
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
    hexdecode(${SCRIPT_ARGN})
else()
    set(HEXDECODE_PATH "${CMAKE_CURRENT_LIST_FILE}")
endif()
