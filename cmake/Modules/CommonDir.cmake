#===============================================================================
#
# Return common directory for given paths
#
# Script usage:
#   `cmake -P /path/to/CommonDir.cmake -- <path>...`
# Result is printed to stdout
#
# CMake usage:
#   `common_dir(<output-variable> <path>...)`
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

function(common_dir output)
    list(POP_FRONT ARGN commonPath)
    if(NOT IS_DIRECTORY commonPath)
        get_filename_component(commonPath "${commonPath}" DIRECTORY)
    endif()
    string(REPLACE "/" ";" commonParts "${commonPath}")
    list(LENGTH commonParts commonPartsLen)

    foreach(path ${ARGN})
        if(NOT IS_DIRECTORY path)
            get_filename_component(path "${path}" DIRECTORY)
        endif()
        string(REPLACE "/" ";" pathParts "${path}")
        list(LENGTH pathParts pathPartsLen)

        if(${commonPartsLen} VERSION_LESS ${pathPartsLen})
            set(minLen ${commonPartsLen})
        else()
            set(minLen ${pathPartsLen})
        endif()
        math(EXPR minLen "${minLen} - 1")

        unset(newCommonParts)
        foreach(i RANGE ${minLen})
            list(GET commonParts ${i} component1)
            list(GET pathParts ${i} component2)
            if(NOT "${component1}" STREQUAL "${component2}")
                break()
            endif()
            list(APPEND newCommonParts ${component1})
        endforeach()

        set(commonParts ${newCommonParts})
        list(LENGTH newCommonParts commonPartsLen)
    endforeach()

    string(JOIN "/" commonPath ${commonParts})
    set(${output} "${commonPath}" PARENT_SCOPE)
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
    common_dir(result ${SCRIPT_ARGN})
    execute_process(COMMAND "${CMAKE_COMMAND}" -E echo "${result}")
else()
    set(COMMON_DIR_PATH "${CMAKE_CURRENT_LIST_FILE}")
endif()
