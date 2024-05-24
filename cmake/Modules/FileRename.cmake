#===============================================================================
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

function(file_rename regex replace)
    cmake_parse_arguments(ARGS "ERROR_QUIET" "" "" ${ARGN})
    foreach(oldName ${ARGS_UNPARSED_ARGUMENTS})
        if(ARGS_ERROR_QUIET AND NOT EXISTS "${oldName}")
            continue()
        endif()
        string(REGEX REPLACE "${regex}" "${replace}" newName "${oldName}")
        file(RENAME "${oldName}" "${newName}")
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
    file_rename(${SCRIPT_ARGN})
else()
    set(FILE_RENAME_PATH "${CMAKE_CURRENT_LIST_FILE}")
endif()
