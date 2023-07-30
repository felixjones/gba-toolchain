#===============================================================================
#
# CMake script for converting string hex to ihex format
#   ihex files can be converted to binary with `objcopy`
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

function(ihex output)
    set(oneValueArgs RECORD_LENGTH)
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "" ${ARGN})

    if(NOT ARGS_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "ihex needs at least 1 input argument.")
    endif()
    list(JOIN ARGS_UNPARSED_ARGUMENTS "" input)

    if(NOT ARGS_RECORD_LENGTH)
        set(ARGS_RECORD_LENGTH 16)
    endif()
    math(EXPR nibbleLength "${ARGS_RECORD_LENGTH} * 2")

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
    set(${output} ":020000040000fa\n") # Start major address 0000

    set(idx 0)
    while(idx LESS ${length})
        # Write a row of data
        string(SUBSTRING "${input}" ${idx} ${nibbleLength} dataString)
        string(LENGTH "${dataString}" dataLength)
        math(EXPR dataLength "${dataLength} / 2")
        normalize_hex(dataLength 2)

        set(dataString "${dataLength}${addrMinor}00${dataString}")
        checksum(crc dataString)
        string(APPEND ${output} ":" "${dataString}" "${crc}" "\n")

        # Calculate next minor address
        math(EXPR addrMinor "0x${addrMinor} + ${ARGS_RECORD_LENGTH}" OUTPUT_FORMAT HEXADECIMAL)

        if("${addrMinor}" GREATER_EQUAL 0x10000)
            # Calculate next major address
            math(EXPR addrMajor "0x${addrMajor} + 1" OUTPUT_FORMAT HEXADECIMAL)
            math(EXPR addrMinor "${addrMinor} - 0x10000" OUTPUT_FORMAT HEXADECIMAL)

            normalize_hex(addrMajor 4)
            set(extendedAddress "02000004${addrMajor}")
            checksum(crc extendedAddress)

            string(APPEND ${output} ":" "${extendedAddress}" "${crc}" "\n")
        endif()

        normalize_hex(addrMinor 4)

        math(EXPR idx "${idx} + ${nibbleLength}")
    endwhile()

    string(APPEND ${output} ":00000001ff\n") # EOF marker
    set(${output} "${${output}}" PARENT_SCOPE)
endfunction()
