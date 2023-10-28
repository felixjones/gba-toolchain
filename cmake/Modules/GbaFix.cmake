#===============================================================================
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

# Create include() function
if(NOT CMAKE_SCRIPT_MODE_FILE)
    set(GBAFIX_SCRIPT "${CMAKE_CURRENT_LIST_FILE}")
    function(gbafix infile)
        execute_process(
            COMMAND "${CMAKE_COMMAND}" -P "${GBAFIX_SCRIPT}" -- "${infile}" "${ARGN}"
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

if(NOT CMAKE_ARGN)
    message(FATAL_ERROR "GbaFix requires input ROM.")
endif()
list(POP_FRONT CMAKE_ARGN input) # First arg is input

cmake_policy(POP)

# Parse arguments
set(options
    DRY_RUN
)
set(oneValueArgs
    TITLE
    ID
    MAKER
    VERSION
)
cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "" ${CMAKE_ARGN})

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
else()
    set(ARGS_VERSION 0)
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
normalize_hex(ARGS_VERSION 2)

# Calculate header complement
string(CONCAT header "${title}" "${id}" "${maker}" "96000000000000000000" "${ARGS_VERSION}")

string(REGEX MATCHALL "([A-Fa-f0-9][A-Fa-f0-9])" headerBytes "${header}")
set(complement 0)
foreach(byte ${headerBytes})
    math(EXPR complement "${complement} + 0x${byte}")
endforeach()
math(EXPR complement "-(0x19 + ${complement})" OUTPUT_FORMAT HEXADECIMAL)
normalize_hex(complement 2)

# For dry-run, we just pass the validation and return
if(ARGS_DRY_RUN)
    if(ARGS_TITLE)
        execute_process(COMMAND "${CMAKE_COMMAND}" -E echo "Title = \"${ARGS_TITLE}\"")
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

        execute_process(COMMAND "${CMAKE_COMMAND}" -E echo "ID = \"${ARGS_ID}\"${extra}")
    endif()
    if(ARGS_MAKER)
        execute_process(COMMAND "${CMAKE_COMMAND}" -E echo "Maker = \"${ARGS_MAKER}\"")
    endif()
    execute_process(COMMAND "${CMAKE_COMMAND}" -E echo "Version = 0x${ARGS_VERSION}")
    execute_process(COMMAND "${CMAKE_COMMAND}" -E echo "Complement = 0x${complement}")
    return()
endif()

# Parse output argument
cmake_policy(PUSH)
cmake_policy(SET CMP0007 NEW)

if(NOT ARGS_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "GbaFix requires output ROM.")
endif()
list(POP_FRONT ARGS_UNPARSED_ARGUMENTS output) # First un-parsed arg is output

cmake_policy(POP)

# Write fixed binary
include("${CMAKE_CURRENT_LIST_DIR}/FileSplit.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Hexdecode.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Mktemp.cmake")

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
