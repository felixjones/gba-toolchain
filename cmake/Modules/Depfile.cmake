#===============================================================================
#
# Write dependency files (DEPFILE)
#
# Script usage:
#   `cmake -P /path/to/Depfile.cmake -- <output-file> [TARGETS <target>... DEPENDENCIES <dependency>...]...`
#
# CMake usage:
#   `depfile(<output-file> [TARGETS <target>... DEPENDENCIES <dependency>...]...)`
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

function(depfile output)
    file(REMOVE "${output}")
    foreach(arg ${ARGN})
        string(REPLACE " " "\\ " arg "${arg}")
        if(NOT state)
            if(arg STREQUAL TARGETS)
                set(state "state-inputs")
            else()
                message(FATAL_ERROR "Expected INPUTS keyword")
            endif()
        elseif(state STREQUAL "state-inputs")
            if(arg STREQUAL DEPENDENCIES)
                set(state "state-outputs")
                file(APPEND "${output}" ":")
            elseif(arg STREQUAL TARGETS)
                message(FATAL_ERROR "Unexpected INPUTS before OUTPUTS")
            else()
                file(APPEND "${output}" "${arg} ")
            endif()
        elseif(state STREQUAL "state-outputs")
            if(arg STREQUAL DEPENDENCIES)
                message(FATAL_ERROR "Unexpected OUTPUTS before INPUTS")
            elseif(arg STREQUAL TARGETS)
                file(APPEND "${output}" "\n")
                set(state "state-inputs")
            else()
                file(APPEND "${output}" " ${arg}")
            endif()
        endif()
    endforeach()
    file(APPEND "${output}" "\n")
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
    depfile(${SCRIPT_ARGN})
else()
    set(DEPFILE_PATH "${CMAKE_CURRENT_LIST_FILE}")
endif()
