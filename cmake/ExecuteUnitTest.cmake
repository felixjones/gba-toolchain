#===============================================================================
#
# CMake script for executing a single unit test
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

file(COPY "${ROM}" DESTINATION .)
get_filename_component(romName "${ROM}" NAME)
file(RENAME "${romName}" "${NAME}.elf")

if(SAVE_FILE)
    file(COPY "${SAVE_FILE}" DESTINATION .)
    get_filename_component(saveName "${SAVE_FILE}" NAME)
    file(RENAME "${saveName}" "${NAME}.sav")
else()
    file(REMOVE "${NAME}.sav")
endif()

execute_process(
    COMMAND "${MGBA}" "${NAME}.elf" -C logToStdout=1 -l 31
    OUTPUT_VARIABLE output
    TIMEOUT ${TIMEOUT}
)

if(NOT output)
    message(FATAL_ERROR "No output (Is TIMEOUT long enough?)")
endif()

message(STATUS "\n${output}--")

foreach(regex ${FAIL_REGULAR_EXPRESSION})
    string(REGEX MATCH "${regex}" match ${output})
    if(match)
        message(FATAL_ERROR "Test fail reason: \"${regex}\" matched \"${match}\"")
    endif()
endforeach()

foreach(regex ${PASS_REGULAR_EXPRESSION})
    string(REGEX MATCH "${regex}" match ${output})
    if(match)
        message(STATUS "Test pass reason: \"${regex}\" matched \"${match}\"")
        return()
    endif()
endforeach()

message(FATAL_ERROR "Test fail reason: No passing regexes.")
