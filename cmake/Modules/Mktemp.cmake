#===============================================================================
#
# Make temporary file
#   Create a file intended to be used for temporary operations
#
# Script usage:
#   `cmake -P /path/to/Mktemp.cmake -- [TMPDIR] [DIRECTORY] [DRY_RUN] [SUFFIX <file-suffix>] [PREFIX <file-prefix>]`
# Result is printed to stdout
#
# CMake usage:
#   `mktemp(<output-variable> [TMPDIR] [DIRECTORY] [DRY_RUN] [SUFFIX <file-suffix>] [PREFIX <file-prefix>])`
#
# `output-variable` stores the resulting path to the temporary file
# `TMPDIR` use the temporary directory.
# `DIRECTORY` create a directory instead of a file.
# `DRY_RUN` do not create the directory or file
# `SUFFIX` file suffix.
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

function(mktemp output)
    # Script begin
    set(options
            TMPDIR
            DIRECTORY
            DRY_RUN
    )
    set(oneValueArgs
            SUFFIX
            PREFIX
    )
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "" ${ARGN})

    # Find template and templateLength
    if(NOT ARGS_UNPARSED_ARGUMENTS)
        set(template "tmp.")
        set(templateLength 10)
    else()
        string(REGEX MATCH "XXX+$" chars "${ARGS_UNPARSED_ARGUMENTS}")
        string(LENGTH "${chars}" templateLength)

        if(templateLength LESS 3)
            message(FATAL_ERROR "TEMPLATE must contain at least 3 consecutive `X's in last component.")
        endif()

        string(LENGTH "${ARGS_UNPARSED_ARGUMENTS}" sublen)
        math(EXPR sublen "${sublen} - ${templateLength}")
        string(SUBSTRING "${ARGS_UNPARSED_ARGUMENTS}" 0 ${sublen} template)
    endif()

    # Find temporary directory
    if(ARGS_TMPDIR)
        if(DEFINED ENV{tmp})
            file(TO_CMAKE_PATH "$ENV{tmp}" ARGS_TMPDIR)
            string(APPEND ARGS_TMPDIR /)
        else()
            set(ARGS_TMPDIR /tmp/)
        endif()
    else()
        unset(ARGS_TMPDIR)
    endif()

    # Attempt to generate unique path
    string(RANDOM LENGTH ${templateLength} random)
    while(EXISTS "${ARGS_TMPDIR}${ARGS_PREFIX}${template}${random}${ARGS_SUFFIX}")
        string(RANDOM LENGTH ${templateLength} random)
    endwhile()
    set(result "${ARGS_TMPDIR}${ARGS_PREFIX}${template}${random}${ARGS_SUFFIX}")

    # When not dry running, actually create the directory/file
    if(NOT ARGS_DRY_RUN)
        if(ARGS_DIRECTORY)
            file(MAKE_DIRECTORY "${result}")
        else()
            file(TOUCH "${result}")
        endif()
    endif()

    set(${output} "${result}" PARENT_SCOPE)
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
    mktemp(result ${SCRIPT_ARGN})
    execute_process(COMMAND "${CMAKE_COMMAND}" -E echo "${result}")
else()
    set(MKTEMP_PATH "${CMAKE_CURRENT_LIST_FILE}")
endif()
