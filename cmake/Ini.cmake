#===============================================================================
#
# Simple CMake .ini configuration reader
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

#! _ini_read_section : Read a named section from an input ini string
#
# Calls set(${_outVariable}_${key} ${value} PARENT_SCOPE) for each key:value pair of
# a given _section in the _input ini string
#
# \arg:_input String contents in ini format
# \arg:_section Name of section to read
# \arg:_outVariable Output variable to write section values
#
function(_ini_read_section _input _section _outVariable)
    string(REGEX REPLACE "([][+.*()^])" "\\\\\\1" section "${_section}")

    string(REGEX REPLACE ";[^\n]*" "" lines "${_input}")
    string(REGEX REPLACE "\n" ";" lines "${lines}")
    list(TRANSFORM lines STRIP)

    foreach(line ${lines})
        if(NOT foundSection)
            string(REGEX MATCH "^[[]${section}[]]$" sectionName "${line}")
            if(sectionName)
                set(foundSection ON)
            endif()
            continue()
        endif()

        string(REGEX MATCH "^[[].*[]]$" sectionName "${line}")
        if(sectionName)
            break()
        endif()

        string(REGEX MATCH "(^[^=]+)[=]([^=]+$)" keyValue ${line})
        string(STRIP "${CMAKE_MATCH_1}" key)
        string(STRIP "${CMAKE_MATCH_2}" value)

        set(${_outVariable}_${key} ${value} PARENT_SCOPE)
    endforeach()
endfunction()
