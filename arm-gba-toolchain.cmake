#===============================================================================
#
# CMake toolchain for compiling GBA ROMs
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

#====================
# Options
#====================

option(USE_CLANG "Enable Clang compiler" OFF)
option(USE_DEVKITARM "Use devkitARM provided compilers and tools" OFF)
set(GBA_TOOLCHAIN_URL "https://github.com/felixjones/gba-toolchain/archive/refs/heads/3.0.zip" CACHE STRING "URL to download GBA toolchain")
set(ARM_GNU_TOOLCHAIN "$ENV{ARM_GNU_TOOLCHAIN}" CACHE PATH "Path to ARM GNU toolchain")

# Tools
set(GBAFIX "$ENV{GBAFIX}" CACHE PATH "Path to gbafix binary")
set(NEDCMAKE "$ENV{NEDCMAKE}" CACHE PATH "Path to nedcmake binary")
set(GBFS "$ENV{GBFS}" CACHE PATH "Path to gbfs binary")
set(BIN2S "$ENV{BIN2S}" CACHE PATH "Path to bin2s binary")
set(PADBIN "$ENV{PADBIN}" CACHE PATH "Path to padbin binary")
set(MMUTIL "$ENV{MMUTIL}" CACHE PATH "Path to mmutil binary")

#====================
# System
#====================

set(CMAKE_SYSTEM_NAME Generic CACHE INTERNAL "" FORCE)
set(CMAKE_SYSTEM_PROCESSOR arm CACHE INTERNAL "" FORCE)
set(GBA ON)

#====================
# Try compile
#====================

set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY" CACHE INTERNAL "" FORCE)
set(GBA_TOOLCHAIN_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "" FORCE)
set(GBA_TOOLCHAIN_TOOLS "${GBA_TOOLCHAIN_LIST_DIR}/tools" CACHE INTERNAL "" FORCE)

#====================
# Host platform
#====================

# Detect MSYS
execute_process(COMMAND uname OUTPUT_VARIABLE uname)
if (uname MATCHES "^MSYS" OR uname MATCHES "^MINGW")
    set(MSYS ON)
endif()

if(WIN32)
    set(HOST_PLATFORM_NAME win32 CACHE INTERNAL "")
    set(HOST_LOCAL_DIRECTORY "$ENV{LocalAppData}" CACHE INTERNAL "")
    set(HOST_APPLICATIONS_DIRECTORIES "$ENV{ProgramFiles}" "$ENV{ProgramFiles\(x86\)}" CACHE INTERNAL "")
    set(HOST_TEMP_DIRECTORY "$ENV{TEMP}" CACHE INTERNAL "")
elseif(UNIX)
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
        if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL aarch64)
            set(HOST_PLATFORM_NAME aarch64-linux CACHE INTERNAL "")
        elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL x86_64)
            set(HOST_PLATFORM_NAME x86_64-linux CACHE INTERNAL "")
        endif()
        set(HOST_APPLICATIONS_DIRECTORIES /bin /usr/bin /usr/share /usr/local /opt CACHE INTERNAL "")
        set(HOST_TEMP_DIRECTORY /tmp CACHE INTERNAL "")
        set(HOST_LOCAL_DIRECTORY ~/ CACHE INTERNAL "")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Darwin)
        set(HOST_PLATFORM_NAME mac CACHE INTERNAL "")
        set(HOST_APPLICATIONS_DIRECTORIES /Applications CACHE INTERNAL "")
        set(HOST_TEMP_DIRECTORY "$ENV{TMPDIR}" CACHE INTERNAL "")
        set(HOST_LOCAL_DIRECTORY /usr/local/share CACHE INTERNAL "")
    elseif(MSYS)
        set(HOST_PLATFORM_NAME win32 CACHE INTERNAL "")

        set(HOST_APPLICATIONS_DIRECTORIES /bin /usr/bin /usr/share /usr/local /opt CACHE INTERNAL "")
        set(HOST_TEMP_DIRECTORY /tmp CACHE INTERNAL "")
        set(HOST_LOCAL_DIRECTORY ~/ CACHE INTERNAL "")
    endif()
endif()

if(NOT HOST_PLATFORM_NAME)
    message(FATAL_ERROR "Unsupported platform \"${CMAKE_HOST_SYSTEM_NAME}\"")
endif()

if(MSYS)
    set(CMAKE_DEPENDS_USE_COMPILER FALSE CACHE INTERNAL "")
endif()

#====================
# Details
#====================

# This should be on local disk due to network file systems breaking CMake lock files
set(GBA_TOOLCHAIN_LOCK "${HOST_TEMP_DIRECTORY}/gba-toolchain.lock" CACHE INTERNAL "" FORCE)
# CMAKE_TOOLCHAIN_FILE should be referenced to hide an invalid warning
set(GBA_TOOLCHAIN_FILE "${CMAKE_TOOLCHAIN_FILE}")

#! _gba_merge : Merge the contents of one folder into another
#
# \arg:_source Path to directory whose contents we wish to copy
# \arg:_destination Path to target directory where copied contents should be
# \param:BACKUP List to store paths to duplicate files
#
function(_gba_merge _source _destination)
    if(NOT EXISTS ${_destination})
        file(RENAME ${_source} ${_destination})
        return()
    endif()

    set(options)
    set(oneValueArgs
        BACKUP
    )
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    file(GLOB_RECURSE sources RELATIVE ${_source} "${_source}/*")
    foreach(src ${sources})
        set(original "${_destination}/${src}")

        if(EXISTS ${original})
            set(i 0)
            while(EXISTS "${original}.bkp${i}")
                math(EXPR i "${i} + 1")
            endwhile()
            set(backup "${original}.bkp${i}")
            file(RENAME ${original} ${backup})

            if(ARGS_BACKUP)
                list(APPEND ${ARGS_BACKUP} ${backup})
            endif()
        endif()

        file(RENAME ${_source}/${src} ${original})
    endforeach()
endfunction()

#! _gba_extract : Archive extraction function based on the script generated by CMake ExternalProject
#
# By default, the archive contents are extracted at the same directory as the archive.
# This can be modified with the DIRECTORY parameter.
#
# \arg:_filename Path to the archive on disk
# \param:MERGE Merge into destination directory
# \param:DIRECTORY Optional target directory to extract to
#
function(_gba_extract _filename)
    get_filename_component(filename "${_filename}" ABSOLUTE)

    set(options
        MERGE
    )
    set(oneValueArgs
        DIRECTORY
    )
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(filename MATCHES "(\\.|=)(7z|tar\\.bz2|tar\\.gz|tar\\.xz|tbz2|tgz|txz|zip)$")
        set(args xfz)
    elseif(filename MATCHES "(\\.|=)tar$")
        set(args xf)
    else()
        message(SEND_ERROR "error: do not know how to extract '${filename}' -- known types are .7z, .tar, .tar.bz2, .tar.gz, .tar.xz, .tbz2, .tgz, .txz and .zip")
        return()
    endif()

    if(ARGS_DIRECTORY)
        get_filename_component(directory "${ARGS_DIRECTORY}" ABSOLUTE)
    else()
        get_filename_component(directory "${filename}" DIRECTORY )
    endif()

    message(STATUS "extracting...
        src='${filename}'
        dst='${directory}'"
    )

    if(NOT EXISTS "${filename}")
        message(FATAL_ERROR "error: file to extract does not exist: '${filename}'")
    endif()

    get_filename_component(name "${filename}" NAME)

    # Prepare a working directory for extracting
    set(i 0)
    while(EXISTS "${directory}/../${name}${i}")
        math(EXPR i "${i} + 1")
    endwhile()
    set(workingDir "${directory}/../${name}${i}")
    file(MAKE_DIRECTORY "${workingDir}")

    # Extract using cmake
    message(STATUS "extracting... [tar ${args}]")
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar ${args} ${filename}
        WORKING_DIRECTORY ${workingDir}
        RESULT_VARIABLE rv
    )

    if(NOT rv EQUAL 0)
        message(STATUS "extracting... [error clean up]")
        file(REMOVE_RECURSE "${workingDir}")
        message(FATAL_ERROR "error: extract of '${filename}' failed")
    endif()

    # Analyze what came out of the archive
    message(STATUS "extracting... [analysis]")
    file(GLOB contents "${workingDir}/*")
    list(REMOVE_ITEM contents "${workingDir}/.DS_Store")
    list(LENGTH contents n)
    if(NOT n EQUAL 1 OR NOT IS_DIRECTORY "${contents}")
        set(contents "${workingDir}")
    endif()

    # Move "the one" directory to the final directory
    if(ARGS_MERGE)
        message(STATUS "extracting... [merging]")
        get_filename_component(contents ${contents} ABSOLUTE)
        _gba_merge(${contents} ${directory})
    else()
        message(STATUS "extracting... [rename]")
        file(REMOVE_RECURSE ${directory})
        get_filename_component(contents ${contents} ABSOLUTE)
        file(RENAME ${contents} ${directory})
    endif()

    # Clean up
    message(STATUS "extracting... [clean up]")
    file(REMOVE_RECURSE "${workingDir}")
    message(STATUS "extracting... done")
endfunction()

#! _gba_download : Downloads to a given path
#
# If the file is an archive, it is extracted to the given path
#
# \arg:_url Source URL of file to download
# \arg:_path Path of where to store the file
# \param:SHOW_PROGRESS Display the download progress %
# \param:MERGE Merge into destination directory
# \param:EXPECTED_HASH <algo>=<value> where <algo> is one of the algorithms supported by file(<HASH>)
# \param:EXPECTED_MD5 Short-hand for EXPECTED_HASH MD5=<value>
# \param:STATUS Store the resulting status of the operation in a variable
#
function(_gba_download _url _path)
    get_filename_component(path "${_path}" ABSOLUTE)

    set(options
        SHOW_PROGRESS
        MERGE
    )
    set(oneValueArgs
        EXPECTED_HASH # <algo>=<value>
        EXPECTED_MD5
        STATUS
    )
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(ARGS_SHOW_PROGRESS)
        set(showProgress SHOW_PROGRESS)
    endif()
    if(ARGS_MERGE)
        set(merge MERGE)
    endif()
    if(ARGS_EXPECTED_HASH)
        set(expectedHash EXPECTED_HASH ${ARGS_EXPECTED_HASH})
    elseif(ARGS_EXPECTED_MD5)
        set(expectedHash EXPECTED_MD5 ${ARGS_EXPECTED_MD5})
    endif()

    get_filename_component(name "${_url}" NAME_WLE)

    # Prepare a working directory for downloading
    set(i 0)
    while(EXISTS "${path}/../${name}${i}")
        math(EXPR i "${i} + 1")
    endwhile()
    set(workingDir "${path}/../${name}${i}")
    file(MAKE_DIRECTORY "${workingDir}")

    get_filename_component(workingFile "${_url}" NAME)
    set(workingFile "${workingDir}/${workingFile}")

    file(DOWNLOAD ${_url} ${workingFile} ${showProgress} ${expectedHash} STATUS downloadStatus)
    list(GET downloadStatus 0 errorCode)
    if(NOT errorCode)
        # Analysis of what we just downloaded
        if(_url MATCHES "(\\.|=)(7z|tar\\.bz2|tar\\.gz|tar\\.xz|tbz2|tgz|txz|zip)$" OR _url MATCHES "(\\.|=)tar$")
            _gba_extract(${workingFile} DIRECTORY ${path} ${merge})
        else()
            file(COPY ${workingFile} DESTINATION ${path})
        endif()
    endif()

    file(REMOVE_RECURSE "${workingDir}")

    if(ARGS_STATUS)
        set(${ARGS_STATUS} ${downloadStatus} PARENT_SCOPE)
    endif()
endfunction()

#====================
# Download gba-toolchain
#====================

# If dependencies.ini missing, then download gba-toolchain
# The assumption is that the user only has the toolchain file
if(NOT EXISTS "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini")
    file(LOCK "${GBA_TOOLCHAIN_LOCK}" GUARD FILE)

    # Prepare a working directory for updating toolchain
    set(i 0)
    while(EXISTS "${GBA_TOOLCHAIN_LIST_DIR}/temp${i}")
        math(EXPR i "${i} + 1")
    endwhile()
    set(workingDir "${GBA_TOOLCHAIN_LIST_DIR}/temp${i}")
    file(MAKE_DIRECTORY "${workingDir}")

    # Download into working directory, then copy contents into toolchain directory
    _gba_download(${GBA_TOOLCHAIN_URL} "${workingDir}")
    file(COPY "${workingDir}/" DESTINATION "${GBA_TOOLCHAIN_LIST_DIR}" PATTERN "arm-gba-toolchain.cmake" EXCLUDE)
    file(REMOVE_RECURSE "${workingDir}")

    file(LOCK "${GBA_TOOLCHAIN_LOCK}" RELEASE)
endif()

#====================
# Includes
#====================

include("${GBA_TOOLCHAIN_LIST_DIR}/cmake/ExtLibraries.cmake")
include("${GBA_TOOLCHAIN_LIST_DIR}/cmake/Gba.cmake")
include("${GBA_TOOLCHAIN_LIST_DIR}/cmake/Ini.cmake")
include("${GBA_TOOLCHAIN_LIST_DIR}/cmake/Toolchain.cmake")

#====================
# Find compilers
#====================

if(USE_DEVKITARM)
    _find_devkitarm()
    set(toolchain $ENV{DEVKITARM})
else()
    file(LOCK "${GBA_TOOLCHAIN_LOCK}" GUARD FILE)
    _find_arm_gnu()
    file(LOCK "${GBA_TOOLCHAIN_LOCK}" RELEASE)
    set(toolchain ${ARM_GNU_TOOLCHAIN})
endif()

if(USE_CLANG)
    _find_clang()
    message(STATUS "Using ARM GNU toolchain (${toolchain}) with Clang ${CLANG_C_COMPILER_VERSION}")
else()
    message(STATUS "Using ARM GNU toolchain (${toolchain}) with GCC ${GNU_C_COMPILER_VERSION}")
endif()

#====================
# Setup toolchain
#====================

_configure_toolchain()
