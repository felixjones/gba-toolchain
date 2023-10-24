#===============================================================================
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

# Create include() function
if(NOT CMAKE_SCRIPT_MODE_FILE)
    set(BINCAT_SCRIPT "${CMAKE_CURRENT_LIST_FILE}")
    function(bincat infile output boundary)
        execute_process(
            COMMAND "${CMAKE_COMMAND}" -P "${BINCAT_SCRIPT}" -- "${infile}" "${output}" ${boundary} "${ARGN}"
        )
    endfunction()
    return()
endif()
unset(CMAKE_SCRIPT_MODE_FILE) # Enable nested include()

# Collect arguments past -- into CMAKE_ARGN
foreach(ii RANGE ${CMAKE_ARGC})
    if("${CMAKE_ARGV${ii}}" STREQUAL --)
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
if(${argc} LESS 3)
    message(FATAL_ERROR "Bincat requires input file, boundary, and output file.")
endif()
list(POP_FRONT CMAKE_ARGN input) # First arg is input
list(POP_FRONT CMAKE_ARGN output) # Second arg is output
list(POP_FRONT CMAKE_ARGN boundary) # Third arg is boundary

cmake_policy(POP)

# Check boundary
math(EXPR boundary "${boundary}")
if(${boundary} LESS_EQUAL 1)
    # Just need to cat into output
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E cat "${input}" ${CMAKE_ARGN}
        OUTPUT_FILE "${output}"
    )
    return()
endif()

# Setup (output will act as an accumulator)
file(COPY_FILE "${input}" "${output}")

include("${CMAKE_CURRENT_LIST_DIR}/Mktemp.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Hexdecode.cmake")

foreach(file ${CMAKE_ARGN})
    # Calculate padding length
    file(SIZE "${output}" filesize)

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
            COMMAND "${CMAKE_COMMAND}" -E cat "${output}" "${tmphex}"
            OUTPUT_FILE "${tmppad}"
        )
        file(REMOVE "${tmphex}")
        file(REMOVE "${output}")
        file(RENAME "${tmppad}" "${output}")
    endif()

    # Append file
    mktemp(tmpcat)
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E cat "${output}" "${file}"
        OUTPUT_FILE "${tmpcat}"
    )
    file(REMOVE "${output}")
    file(RENAME "${tmpcat}" "${output}")
endforeach()
