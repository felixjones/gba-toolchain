#===============================================================================
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

# Create include() function
if(NOT CMAKE_SCRIPT_MODE_FILE)
    set(HEXDECODE_SCRIPT "${CMAKE_CURRENT_LIST_FILE}")
    function(hexdecode outfile)
        execute_process(
            COMMAND "${CMAKE_COMMAND}" -P "${HEXDECODE_SCRIPT}" -- "${outfile}" "${ARGN}"
        )
    endfunction()
    return()
endif()
unset(CMAKE_SCRIPT_MODE_FILE) # Enable nested include()

# Collect arguments past -- into CMAKE_ARGN
foreach(ii RANGE ${CMAKE_ARGC})
    if(${ii} EQUAL ${CMAKE_ARGC})
        break()
    elseif("${CMAKE_ARGV${ii}}" STREQUAL --)
        set(start ${ii})
    elseif(DEFINED start)
        list(APPEND CMAKE_ARGN "${CMAKE_ARGV${ii}}")
    endif()
endforeach()
unset(start)

# Script begin

cmake_policy(PUSH)
cmake_policy(SET CMP0007 NEW)

list(LENGTH CMAKE_ARGN argc)
if(argc LESS 2)
    message(FATAL_ERROR "hexdecode requires at least 2 arguments.")
endif()

list(POP_FRONT CMAKE_ARGN outfile) # First arg is output

cmake_policy(POP)

# Join all hex lists
string(JOIN "" hexes ${CMAKE_ARGN})

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
include("${CMAKE_CURRENT_LIST_DIR}/IHex.cmake" OPTIONAL RESULT_VARIABLE IHEX_INCLUDED)
include("${CMAKE_CURRENT_LIST_DIR}/Mktemp.cmake" OPTIONAL RESULT_VARIABLE MKTEMP_INCLUDED)
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
