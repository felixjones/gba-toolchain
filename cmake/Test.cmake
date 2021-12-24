#===============================================================================
#
# CMake toolchain configuration package for GBA unit tests
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

#! gba_target_add_test : Constructs a wrapped test using mGBA
#
# REQUIRES mGBA!
# GBA tests rely on mGBA logging to stdout and testing these against passing/failing regexes
# Because GBA ROMs cannot currently instruct mGBA to exit, the unit tests must use a timeout
# By default, a ctest timeout means fail, so instead the output is wrapped via a CMake script
#
# \arg:_target Target to run the test for
# \arg:_test Name of the test
# \param:TIMEOUT Timeout in seconds (required to run for as long as it takes to produce output)
# \param:SAVE_FILE Optional path to a save file to use with this test
# \param:PASS_REGULAR_EXPRESSION List of regular expressions that pass this test
# \param:FAIL_REGULAR_EXPRESSION List of regular expressions that fail this test
#
function(gba_target_add_test _target _test)
    set(options)
    set(oneValueArgs
        TIMEOUT
        SAVE_FILE
    )
    set(multiValueArgs
        PASS_REGULAR_EXPRESSION
        FAIL_REGULAR_EXPRESSION
    )
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT ARGS_TIMEOUT)
        message(FATAL_ERROR "GBA tests require a TIMEOUT")
    endif()

    if(NOT ARGS_PASS_REGULAR_EXPRESSION AND NOT ARGS_FAIL_REGULAR_EXPRESSION)
        message(FATAL_ERROR "GBA tests require pass or fail regular expessiones")
    endif()

    _gba_find_mgba()

    if(ARGS_SAVE_FILE)
        set(saveFile -DSAVE_FILE=${ARGS_SAVE_FILE})
    endif()

    add_test(NAME ${_test}
        COMMAND "${CMAKE_COMMAND}"
            -DNAME=${_test}
            -DMGBA=${MGBA}
            -DROM=$<TARGET_FILE:${_target}>
            ${saveFile}
            -DTIMEOUT=${ARGS_TIMEOUT}
            -DPASS_REGULAR_EXPRESSION=${ARGS_PASS_REGULAR_EXPRESSION}
            -DFAIL_REGULAR_EXPRESSION=${ARGS_FAIL_REGULAR_EXPRESSION}
            -P "${GBA_TOOLCHAIN_LIST_DIR}/cmake/ExecuteUnitTest.cmake"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/Testing"
    )
endfunction()

#! _gba_find_mgba : Attempts to locate mGBA
#
# If MGBA is found, it is stored in the cache variable MGBA
#
function(_gba_find_mgba)
    if(EXISTS "${MGBA}")
        return()
    endif()

    # Searches:
    #   Environment Path
    #   Windows ProgramFiles and ProgramFiles(x86)
    #   GBA_TOOLCHAIN_LIST_DIR
    set(searchPaths $ENV{Path})
    list(APPEND searchPaths "${HOST_APPLICATIONS_DIRECTORIES}")
    list(APPEND searchPaths "${HOST_LOCAL_DIRECTORY}")
    list(APPEND searchPaths "${GBA_TOOLCHAIN_LIST_DIR}")

    find_program(mGBA NAMES mgba PATH_SUFFIXES mGBA PATHS ${searchPaths})
    if(NOT EXISTS "${mGBA}")
        message(FATAL_ERROR "Could not locate mGBA")
    endif()

    set(MGBA "${mGBA}" CACHE PATH "Path to mGBA binary" FORCE)
endfunction()
