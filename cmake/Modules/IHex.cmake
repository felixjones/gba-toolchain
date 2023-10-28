#===============================================================================
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

# Create include() function
if(NOT CMAKE_SCRIPT_MODE_FILE)
    set(IHEX_SCRIPT "${CMAKE_CURRENT_LIST_FILE}")
    function(ihex output)
        execute_process(
            COMMAND "${CMAKE_COMMAND}" -P "${IHEX_SCRIPT}" -- "${ARGN}"
            OUTPUT_VARIABLE outputVariable OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        set("${output}" "${outputVariable}" PARENT_SCOPE)
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

set(oneValueArgs RECORD_LENGTH)
cmake_parse_arguments(ARGS "" "${oneValueArgs}" "" ${CMAKE_ARGN})

if(NOT ARGS_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "ihex needs at least 1 input argument.")
endif()
list(JOIN ARGS_UNPARSED_ARGUMENTS "" input)

string(REGEX MATCH "^[0-9A-Fa-f]+$" isHex ${input})
if(NOT isHex STREQUAL input)
    message(FATAL_ERROR "Input is not a valid hex string. ${input}")
endif()

if(NOT ARGS_RECORD_LENGTH)
    set(ARGS_RECORD_LENGTH 16)
endif()
math(EXPR nibbleLength "${ARGS_RECORD_LENGTH} * 2")

# Useful after CMake math(EXPR ...) calls
macro(normalize_hex hex nibbleCount)
    if(NOT "${${hex}}" MATCHES "0x")
        math(EXPR ${hex} "${${hex}}" OUTPUT_FORMAT HEXADECIMAL)
    endif()
    string(REGEX REPLACE "^0x" "" ${hex} "${${hex}}")
    string(REPEAT "0" ${nibbleCount} padding)
    set(${hex} "${padding}${${hex}}")
    string(LENGTH "${${hex}}" padding)
    math(EXPR padding "${padding} - ${nibbleCount}")
    string(SUBSTRING "${${hex}}" ${padding} -1 ${hex})
endmacro()

# ihex checksum algorithm
macro(checksum result hexNibbles)
    string(REGEX MATCHALL "([A-Fa-f0-9][A-Fa-f0-9])" hexBytes ${${hexNibbles}})

    set(${result} 0)
    foreach(byte ${hexBytes})
        math(EXPR ${result} "${${result}} + 0x${byte}")
    endforeach()
    math(EXPR ${result} "1 + ~${${result}}" OUTPUT_FORMAT HEXADECIMAL)
    normalize_hex(${result} 2)
endmacro()

string(LENGTH "${input}" length)

set(addrMajor 0000)
set(addrMinor 0000)
execute_process(COMMAND "${CMAKE_COMMAND}" -E echo ":020000040000fa") # Start major address 0000

set(idx 0)
while(idx LESS ${length})
    # Write a row of data
    string(SUBSTRING "${input}" ${idx} ${nibbleLength} dataString)
    string(LENGTH "${dataString}" dataLength)
    math(EXPR dataLength "${dataLength} / 2")
    normalize_hex(dataLength 2)

    set(dataString "${dataLength}${addrMinor}00${dataString}")
    checksum(crc dataString)
    execute_process(COMMAND "${CMAKE_COMMAND}" -E echo ":${dataString}${crc}")

    # Calculate next minor address
    math(EXPR addrMinor "0x${addrMinor} + ${ARGS_RECORD_LENGTH}" OUTPUT_FORMAT HEXADECIMAL)

    if("${addrMinor}" GREATER_EQUAL 0x10000)
        # Calculate next major address
        math(EXPR addrMajor "0x${addrMajor} + 1" OUTPUT_FORMAT HEXADECIMAL)
        math(EXPR addrMinor "${addrMinor} - 0x10000" OUTPUT_FORMAT HEXADECIMAL)

        normalize_hex(addrMajor 4)
        set(extendedAddress "02000004${addrMajor}")
        checksum(crc extendedAddress)

        execute_process(COMMAND "${CMAKE_COMMAND}" -E echo ":${extendedAddress}${crc}")
    endif()

    normalize_hex(addrMinor 4)

    math(EXPR idx "${idx} + ${nibbleLength}")
endwhile()

execute_process(COMMAND "${CMAKE_COMMAND}" -E echo ":00000001ff") # EOF marker
