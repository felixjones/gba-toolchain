#===============================================================================
#
# GBA ROM fix-up utility
#   Fixes the header of a GBA ROM to make it bootable on hardware
#
# Script usage:
#   `cmake -P /path/to/GbaFix.cmake -- <input-file> [TITLE <12-character-string>] [ID <4-character-string>] [MAKER <2-character-string>] [VERSION <1-byte-number>] [<output-file>]`
#
# CMake usage:
#   `gbafix(<input-file> [TITLE <12-character-string>] [ID <4-character-string>] [MAKER <2-character-string>] [VERSION <1-byte-number>] [<output-file>])`
#
# If `output-file` is not specified: `input-file` will instead be replaced with the fixed output.
#
# `TITLE` 12 character name.
# `ID` 4 character ID in UTTD format. The first character (U) suggests save-type*. The last character (D) suggests region/language**.
# `MAKER` 2 character maker ID.
# `VERSION` 1 byte numeric version (0-255).
#     *Known save types:
#         `1` EEPROM
#         `2` SRAM
#         `3` FLASH-64
#         `4` FLASH-128
#     **Known regions/languages:
#         `J` Japan
#         `P` Europe/Elsewhere
#         `F` French
#         `S` Spanish
#         `E` USA/English
#         `D` German
#         `I` Italian
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include("${CMAKE_CURRENT_LIST_DIR}/FileSplit.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Hexdecode.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Mktemp.cmake")

function(gbafix input)
    set(oneValueArgs
            TITLE
            ID
            MAKER
            VERSION
    )
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "" ${ARGN})

    # Validate args
    string(LENGTH "${ARGS_TITLE}" titleLength)
    if (${titleLength} GREATER 12)
        message(FATAL_ERROR "TITLE \"${ARGS_TITLE}\" must not be more than 12 characters")
    endif()

    string(LENGTH "${ARGS_ID}" idLength)
    if (${idLength} GREATER 4)
        message(FATAL_ERROR "ID \"${ARGS_ID}\" must not be more than 4 characters")
    endif()

    string(LENGTH "${ARGS_MAKER}" makerLength)
    if (${makerLength} GREATER 2)
        message(FATAL_ERROR "MAKER \"${ARGS_MAKER}\" must not be more than 2 characters")
    endif()

    if(ARGS_VERSION)
        math(EXPR HEX_VERSION "${ARGS_VERSION}" OUTPUT_FORMAT HEXADECIMAL)
        if(${HEX_VERSION} LESS 0 OR ${HEX_VERSION} GREATER 255)
            message(FATAL_ERROR "VERSION \"${ARGS_VERSION}\" must be between 0 and 255")
        endif()
    endif()

    # Set the output file
    if(input STREQUAL VERIFY)
        set(verify 1)
    endif()
    if(NOT ARGS_UNPARSED_ARGUMENTS AND NOT verify)
        set(output "${input}")
    elseif(ARGS_UNPARSED_ARGUMENTS AND verify)
        message(WARNING "Output \"${ARGS_UNPARSED_ARGUMENTS}\" specified, however VERIFY will produce no output.")
    elseif(ARGS_UNPARSED_ARGUMENTS)
        set(output "${ARGS_UNPARSED_ARGUMENTS}")
    endif()

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

    # Pads a given string with ASCII '0' up until the given length
    macro(pad string length)
        string(LENGTH "${${string}}" stringLength)
        math(EXPR padLength "${length} - ${stringLength}")

        if(padLength GREATER 0)
            string(REPEAT "0" ${padLength} padding)
            set(${string} "${${string}}${padding}")
        endif()
    endmacro()

    # Convert to hex, apply padding, and normalize
    string(HEX "${ARGS_TITLE}" title)
    pad(title 24)
    string(HEX "${ARGS_ID}" id)
    pad(id 8)
    string(HEX "${ARGS_MAKER}" maker)
    pad(maker 4)

    # Calculate header complement
    if(ARGS_VERSION)
        set(version ${ARGS_VERSION})
        normalize_hex(version 2)
    else()
        set(version "00")
    endif()
    string(CONCAT header "${title}" "${id}" "${maker}" "96000000000000000000" "${version}")

    string(REGEX MATCHALL "([A-Fa-f0-9][A-Fa-f0-9])" headerBytes "${header}")
    set(complement 0)
    foreach(byte ${headerBytes})
        math(EXPR complement "${complement} + 0x${byte}")
    endforeach()
    math(EXPR complement "-(0x19 + ${complement})" OUTPUT_FORMAT HEXADECIMAL)
    normalize_hex(complement 2)

    # For VERIFY, we just pass the validation and return
    if(verify)
        if(ARGS_TITLE)
            message(STATUS "Title = \"${ARGS_TITLE}\"")
        endif()
        if(ARGS_ID)
            unset(extra)

            # U code
            if(ARGS_ID MATCHES "^1")
                string(APPEND extra " [1] EverDrive EEPROM")
            elseif(ARGS_ID MATCHES "^2")
                string(APPEND extra " [2] EverDrive SRAM")
            elseif(ARGS_ID MATCHES "^3")
                string(APPEND extra " [3] EverDrive FLASH-64")
            elseif(ARGS_ID MATCHES "^4")
                string(APPEND extra " [4] EverDrive FLASH-128")
            endif()

            # D code
            if(ARGS_ID MATCHES "J$")
                string(APPEND extra " [J] Japan")
            elseif(ARGS_ID MATCHES "P$")
                string(APPEND extra " [P] Europe/Elsewhere")
            elseif(ARGS_ID MATCHES "F$")
                string(APPEND extra " [F] French")
            elseif(ARGS_ID MATCHES "S$")
                string(APPEND extra " [S] Spanish")
            elseif(ARGS_ID MATCHES "E$")
                string(APPEND extra " [E] USA/English")
            elseif(ARGS_ID MATCHES "D$")
                string(APPEND extra " [D] German")
            elseif(ARGS_ID MATCHES "I$")
                string(APPEND extra " [I] Italian")
            endif()

            message(STATUS "ID = \"${ARGS_ID}\"${extra}")
        endif()
        if(ARGS_MAKER)
            message(STATUS "Maker = \"${ARGS_MAKER}\"")
        endif()
        if(ARGS_VERSION)
            message(STATUS "Version = 0x${version}")
        endif()
        message(STATUS "Complement = 0x${complement}")
        return()
    endif()

    # Split ROM into 3 parts
    mktemp(part1)
    mktemp(part2)
    mktemp(part3)

    file_split("${input}"
            OUTPUT "${part1}" LENGTH 160    # Entrypoint + Logo
            OUTPUT "${part2}" LENGTH 32     # Header
            OUTPUT "${part3}"               # Remaining ROM
    )

    # Override part2 with fixed header
    hexdecode("${part2}" "${header}" "${complement}" 0000)

    # Concat
    execute_process(
            COMMAND "${CMAKE_COMMAND}" -E cat "${part1}" "${part2}" "${part3}"
            OUTPUT_FILE "${output}"
    )

    # Cleanup temporaries
    file(REMOVE "${part3}")
    file(REMOVE "${part2}")
    file(REMOVE "${part1}")
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
    gbafix(${SCRIPT_ARGN})
else()
    set(GBAFIX_PATH "${CMAKE_CURRENT_LIST_FILE}")
endif()
