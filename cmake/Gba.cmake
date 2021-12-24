#===============================================================================
#
# CMake toolchain configuration package for GBA helper CMake functions
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

#! gba_add_library_subdirectory : Adds a subdirectory from gba-toolchain libraries
#
# Additional gba-toolchain libraries can be added as additional parameters
#
# \arg:_library Name of gba-toolchain library to add
# \group:ARGN List of additional gba-toolchain libraries to add
#
function(gba_add_library_subdirectory _library)
    function(_gba_add_one_library_subdirectory _library)
        if(${_library} STREQUAL tonc)
            file(LOCK "${GBA_TOOLCHAIN_LOCK}" GUARD FILE)
            _gba_find_ext_tonclib()
            file(LOCK "${GBA_TOOLCHAIN_LOCK}" RELEASE)
        endif()
        if(${_library} STREQUAL seven)
            file(LOCK "${GBA_TOOLCHAIN_LOCK}" GUARD FILE)
            _gba_find_ext_libseven()
            file(LOCK "${GBA_TOOLCHAIN_LOCK}" RELEASE)
        endif()
        if(${_library} STREQUAL gbfs)
            file(LOCK "${GBA_TOOLCHAIN_LOCK}" GUARD FILE)
            _gba_find_gbfs()
            file(LOCK "${GBA_TOOLCHAIN_LOCK}" RELEASE)
        endif()

        get_filename_component(libraryDir "${GBA_TOOLCHAIN_LIST_DIR}/lib/${_library}" ABSOLUTE)
        add_subdirectory("${libraryDir}" "${_library}")

        # Handle scripts for runtime libraries
        if(${_library} STREQUAL rom OR ${_library} STREQUAL multiboot OR ${_library} STREQUAL ereader)
            string(TOUPPER "${_library}" libraryUpper)

            set(GBA_${libraryUpper}_LDSCRIPT "${GBA_${libraryUpper}_LDSCRIPT}" CACHE INTERNAL "")
            set(GBA_${libraryUpper}_SPECS "${GBA_${libraryUpper}_SPECS}" CACHE INTERNAL "")
            set(GBA_${libraryUpper}_BINARY_DIR "${GBA_${libraryUpper}_BINARY_DIR}" CACHE INTERNAL "")
        endif()
    endfunction()

    _gba_add_one_library_subdirectory(${_library})

    foreach(arg ${ARGN})
        _gba_add_one_library_subdirectory(${arg})
    endforeach()
endfunction()

#! gba_link_runtime_library : Link a given target against a runtime library
#
# This essentially sorts out the target_link_libraries variables required for runtime linking
#
# \arg:_target Name of target to link library to
# \arg:_library Name of a valid runtime library (rom, multiboot, ereader)
#
function(gba_target_link_runtime_library _target _library)
    get_target_property(runtime ${_target} RUNTIME)
    if(runtime)
        message(FATAL_ERROR "Target ${_target} is already linked with ${runtime} runtime")
    endif()

    add_dependencies(${_target} ${_library})

    string(TOUPPER ${_library} libraryUpper)

    target_link_libraries(${_target} PRIVATE
        "-T \"${GBA_${libraryUpper}_LDSCRIPT}\""
        "-specs=\"${GBA_${libraryUpper}_SPECS}\""
        "-B \"${GBA_${libraryUpper}_BINARY_DIR}\""
    )

    set_target_properties(${_target} PROPERTIES RUNTIME ${_library})
endfunction()

#! gba_target_sources_compile_options : Add compile options to IWRAM and/or EWRAM sources
#
# \arg:_target Target for applying compile options to sources
# \param:IWRAM List of compile flags for IWRAM sources
# \param:EWRAM List of compile flags for EWRAM sources
#
function(gba_target_sources_compile_options _target)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs
        IWRAM
        EWRAM
    )
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT ARGS_IWRAM AND NOT ARGS_EWRAM)
        message(WARNING "gba_target_sources_compile_options called without IWRAM or EWRAM compile options")
        return()
    endif()

    if(ARGS_IWRAM)
        list(JOIN ARGS_IWRAM " " flags)
        get_target_property(sources ${_target} SOURCES)
        list(FILTER sources INCLUDE REGEX "(.*\\.iwram[0-9]?\\..*)")
        foreach(source ${sources})
            set_source_files_properties(${source} PROPERTIES COMPILE_FLAGS ${flags})
        endforeach()
    endif()

    if(ARGS_EWRAM)
        list(JOIN ARGS_EWRAM " " flags)
        get_target_property(sources ${_target} SOURCES)
        list(FILTER sources INCLUDE REGEX "(.*\\.ewram[0-9]?\\..*)")
        foreach(source ${sources})
            set_source_files_properties(${source} PROPERTIES COMPILE_FLAGS "${flags}")
        endforeach()
    endif()
endfunction()

#! gba_target_objcopy : objcopy command
#
# objcopy is used to compile a .elf output to a binary output
# By default, the output is the target name with .gba or .bin extension
#
# If the FIX_HEADER parameter is used then gbafix is added as an additional command
# If the ARCHIVE_DOTCODE parameter is used then nedcmake is added as an additional command
#
# \arg:_target Target to add the objcopy step to
# \param:OUTPUT Optional name of the binary file to output to
# \param:PAD Pad ROM to next given byte
# \param:FIX_HEADER Use gbafix to fix ROM header
# \param:   TITLE (Requires FIX_HEADER) 12 character ROM title. Default is input file name.
# \param:   GAME_CODE (Requires FIX_HEADER) 4 character game code in UTTD format
# \param:   MAKER_CODE (Requires FIX_HEADER) 2 character maker code
# \param:   VERSION (Requires FIX_HEADER) Integer ROM version number, up to 255
# \param:ARCHIVE_DOTCODE Use nedclib to generate dotcodes
# \param:   REGION (Requires ARCHIVE_DOTCODE) "usa" or "jap+" (default is "usa")
# \param:   NAME (Requires ARCHIVE_DOTCODE) Application name
#
function(gba_target_objcopy _target)
    set(options
        FIX_HEADER
        # gbafix
        ARCHIVE_DOTCODE
    )
    set(oneValueArgs
        OUTPUT
        # gbafix
        TITLE
        GAME_CODE
        MAKER_CODE
        VERSION
        # nedcmake
        REGION
        NAME
        # gbfs
        PAD
    )
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Ideally this would use $<TARGET_FILE_NAME:${_target}>
    # However, generator expressions are not supported in BYPRODUCTS for add_custom_command
    # https://gitlab.kitware.com/cmake/cmake/-/issues/12877
    get_target_property(runtime ${_target} RUNTIME)
    if(ARGS_OUTPUT)
        set(objcopyOutput "${ARGS_OUTPUT}")
    elseif(runtime STREQUAL ereader)
        set(objcopyOutput "${_target}.bin")
    else()
        set(objcopyOutput "${_target}.gba")
    endif()
    get_filename_component(objcopyName "${objcopyOutput}" NAME_WE)
    set_target_properties(${_target} PROPERTIES OBJCOPY_OUTPUT "${CMAKE_BINARY_DIR}/${objcopyOutput}")

    # Pad ROM to byte
    if(ARGS_PAD)
        if (ARGS_PAD MATCHES "^[0-9]+$")
            file(LOCK "${GBA_TOOLCHAIN_LOCK}" GUARD FILE)
            _gba_find_gbfs()
            file(LOCK "${GBA_TOOLCHAIN_LOCK}" RELEASE)

            set(padCommand COMMAND "${PADBIN}" "${ARGS_PAD}" "${objcopyOutput}")
        else()
            message(FATAL_ERROR "PAD requires number (was given ${ARGS_PAD})")
        endif()
    endif()

    add_custom_command(TARGET ${_target}
        POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E echo "Copying object ${objcopyOutput}"
        COMMAND "${GNU_OBJCOPY}" -O binary "$<TARGET_FILE:${_target}>" "${objcopyOutput}"
        ${padCommand}
        BYPRODUCTS "${objcopyOutput}"
    )

    if(ARGS_ARCHIVE_DOTCODE)
        if(NOT runtime STREQUAL ereader)
            message(FATAL_ERROR "Parameter ARCHIVE_DOTCODE is invalid for ${runtime} binaries")
        endif()

        file(LOCK "${GBA_TOOLCHAIN_LOCK}" GUARD FILE)
        _gba_find_nedcmake()
        file(LOCK "${GBA_TOOLCHAIN_LOCK}" RELEASE)

        set(nedcmakeArgs -type 2 -bmp)

        # Set application name
        if(ARGS_NAME)
            list(APPEND nedcmakeArgs -name "${ARGS_NAME}")
        endif()

        # Set card titles
        foreach(cardTitle ${ARGS_CARD_TITLES})
            list(APPEND nedcmakeArgs -title "${cardTitle}")
        endforeach()

        # Set save file
        if(ARGS_ALLOW_SAVE)
            list(APPEND nedcmakeArgs -save)
        endif()

        # Set region
        if(ARGS_REGION STREQUAL usa)
            list(APPEND nedcmakeArgs -region 1)
        elseif(ARGS_REGION STREQUAL jap+)
            list(APPEND nedcmakeArgs -region 2)
        elseif(ARGS_REGION)
            message(FATAL_ERROR "Unknown e-reader region ${ARGS_REGION}")
        endif()

        # Construct commands for cleaning any previous output (assuming a maximum of 12 cards)
        foreach(i RANGE 1 12)
            string(LENGTH "${i}" length)
            if(${length} EQUAL 1)
                set(i "0${i}")
            endif()

            list(APPEND cmakeRemoveCardCommand
                COMMAND "${CMAKE_COMMAND}" -E remove -f "${objcopyName}-${i}.bmp"
            )
        endforeach()

        add_custom_command(TARGET ${_target}
            POST_BUILD
            ${cmakeRemoveCardCommand}
            COMMAND "${CMAKE_COMMAND}" -E echo "Archiving dotcodes ${objcopyOutput}"
            COMMAND "${NEDCMAKE}" -i "${objcopyOutput}" -o "${objcopyName}" ${nedcmakeArgs}
        )
    endif()

    if(ARGS_FIX_HEADER)
        if(runtime STREQUAL ereader)
            message(FATAL_ERROR "Parameter FIX_HEADER is invalid for ereader binaries")
        endif()

        file(LOCK "${GBA_TOOLCHAIN_LOCK}" GUARD FILE)
        _gba_find_gbafix()
        file(LOCK "${GBA_TOOLCHAIN_LOCK}" RELEASE)

        # ROM title
        if(ARGS_TITLE)
            string(LENGTH "${ARGS_TITLE}" titleLength)
            if (${titleLength} GREATER 12)
                message(FATAL_ERROR "gba_target_objcopy title \"${ARGS_TITLE}\" must not be more than 12 characters!")
            endif()
            list(APPEND gbafixArgs -t${ARGS_TITLE})
        endif()

        # 4 character UTTD code
        if(ARGS_GAME_CODE)
            string(LENGTH "${ARGS_GAME_CODE}" gameCodeLength)
            if (NOT ${gameCodeLength} EQUAL 4)
                message(FATAL_ERROR "gba_target_objcopy game code \"${ARGS_GAME_CODE}\" must be 4 characters!")
            endif()
            list(APPEND gbafixArgs -c${ARGS_GAME_CODE})
        endif()

        # 2 character maker code
        if(ARGS_MAKER_CODE)
            string(LENGTH "${ARGS_MAKER_CODE}" makerCodeLength)
            if (NOT ${makerCodeLength} EQUAL 2)
                message(FATAL_ERROR "gba_target_objcopy maker code \"${ARGS_MAKER_CODE}\" must be 2 characters!")
            endif()
            list(APPEND gbafixArgs -m${ARGS_MAKER_CODE})
        endif()

        # Version number up to 255
        if(ARGS_VERSION)
            if(NOT ${ARGS_VERSION} MATCHES "^[0-9]+$")
                message(FATAL_ERROR "gba_target_objcopy version ${ARGS_VERSION} must be a positive number!")
            endif()
            if(${ARGS_VERSION} GREATER 255)
                message(FATAL_ERROR "gba_target_objcopy version ${ARGS_VERSION} must be less than 256!")
            endif()

            list(APPEND gbafixArgs -r${ARGS_VERSION})
        endif()

        add_custom_command(TARGET ${_target}
            POST_BUILD
            COMMAND "${CMAKE_COMMAND}" -E echo "Fixing header ${objcopyOutput} ${gbafixArgs}"
            COMMAND "${GBAFIX}" "${objcopyOutput}" ${gbafixArgs}
        )
    endif()
endfunction()

#! gba_add_gbfs : create gbfs archive target
#
# GBFS is used to bundle assets together into an archive that can be read by libgbfs
# This command supports adding dependant targets
# assuming that they are GBA targets that have a property "OBJCOPY_OUTPUT"
#
# \arg:_target Name of the gbfs target to create
# \group:ARGN List of sources and/or targets to add to this gbfs archive
#
function(gba_add_gbfs _target)
    set(options
        GENERATE_ASM
    )
    set(oneValueArgs)
    set(multiValueArgs)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT ARGS_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "No SOURCES given to target: ${_target}")
    endif()

    file(LOCK "${GBA_TOOLCHAIN_LOCK}" GUARD FILE)
    _gba_find_gbfs()
    file(LOCK "${GBA_TOOLCHAIN_LOCK}" RELEASE)

    add_custom_target(${_target} ALL
        COMMAND "${GBFS}" $<TARGET_GENEX_EVAL:${_target},$<TARGET_PROPERTY:${_target},TARGET_FILE>> ${ARGS_UNPARSED_ARGUMENTS}
        COMMENT  "Compiling GBFS ${_target}"
        SOURCES ${ARGS_UNPARSED_ARGUMENTS}
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    )

    if (ARGS_GENERATE_ASM)
        # Ideally this would use $<TARGET_FILE_NAME:${_target}>
        # However, generator expressions are not supported in BYPRODUCTS for add_custom_command
        # https://gitlab.kitware.com/cmake/cmake/-/issues/12877
        add_custom_command(TARGET ${_target}
            POST_BUILD
            COMMAND "${BIN2S}" "$<TARGET_GENEX_EVAL:${_target},$<TARGET_PROPERTY:${_target},TARGET_FILE_NAME>>" ">" "${_target}.s"
            BYPRODUCTS "${_target}.s"
            WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        )
        set_property(TARGET ${_target} PROPERTY ASM_OUTPUT "${CMAKE_BINARY_DIR}/${_target}.s")
    endif()

    set_property(TARGET ${_target} PROPERTY OUTPUT_NAME ${_target})

    set_property(TARGET ${_target} PROPERTY TARGET_FILE_BASE_NAME $<TARGET_GENEX_EVAL:${_target},$<TARGET_PROPERTY:${_target},OUTPUT_NAME>>)
    set_property(TARGET ${_target} PROPERTY TARGET_FILE_DIR $<TARGET_GENEX_EVAL:${_target},$<TARGET_PROPERTY:${_target},BINARY_DIR>>)
    set_property(TARGET ${_target} PROPERTY TARGET_FILE_PREFIX $<TARGET_GENEX_EVAL:${_target},$<TARGET_PROPERTY:${_target},PREFIX>>)
    set_property(TARGET ${_target} PROPERTY TARGET_FILE_SUFFIX $<TARGET_GENEX_EVAL:${_target},$<TARGET_PROPERTY:${_target},SUFFIX>>)
    set_property(TARGET ${_target} PROPERTY TARGET_FILE_NAME
        $<TARGET_GENEX_EVAL:${_target},$<TARGET_PROPERTY:${_target},TARGET_FILE_PREFIX>>$<TARGET_GENEX_EVAL:${_target},$<TARGET_PROPERTY:${_target},TARGET_FILE_BASE_NAME>>$<TARGET_GENEX_EVAL:${_target},$<TARGET_PROPERTY:${_target},TARGET_FILE_SUFFIX>>
    )
    set_property(TARGET ${_target} PROPERTY TARGET_FILE
        $<TARGET_GENEX_EVAL:${_target},$<TARGET_PROPERTY:${_target},TARGET_FILE_DIR>>/$<TARGET_GENEX_EVAL:${_target},$<TARGET_PROPERTY:${_target},TARGET_FILE_NAME>>
    )
endfunction()

#! _gba_find_gbafix : Locate and download gbafix
#
# gbafix is used by gba_target_objcopy to "fix" GBA ROM headers
# If it is not available, it is downloaded from the gbafix URL in dependencies.ini
# The path to the gbafix binary is stored in GBAFIX
#
function(_gba_find_gbafix)
    if(NOT EXISTS "${GBAFIX}")
        # Searches:
        #   Environment Path
        #   Windows %LocalAppData%
        #   *NIX opt/local/
        #   GBA_TOOLCHAIN_TOOLS/tools
        set(searchPaths $ENV{Path})
        list(APPEND searchPaths "${HOST_LOCAL_DIRECTORY}")
        list(APPEND searchPaths "${GBA_TOOLCHAIN_TOOLS}/gbafix")

        # Test for gbafix
        find_program(gbafixBinary NAMES "gbafix" PATHS ${searchPaths})
        if(gbafixBinary)
            # Update cached entry
            set(GBAFIX "${gbafixBinary}" CACHE PATH "Path to gbafix binary" FORCE)
        else()
            if(NOT EXISTS "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini")
                if(NOT DEPENDENCIES_URL)
                    message(FATAL_ERROR "Missing DEPENDENCIES_URL")
                endif()

                file(DOWNLOAD "${DEPENDENCIES_URL}" "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini" SHOW_PROGRESS)
            endif()

            file(READ "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini" iniFile)
            _ini_read_section("${iniFile}" "gbafix" gbafix)

            get_filename_component(ARM_GNU_TOOLCHAIN "${HOST_LOCAL_DIRECTORY}/arm-gnu-toolchain" ABSOLUTE)
            message(STATUS "Downloading gbafix.c from \"${gbafix_url}\" to \"${GBA_TOOLCHAIN_TOOLS}/gbafix\"")
            _gba_download("${gbafix_url}" "${GBA_TOOLCHAIN_TOOLS}/gbafix" SHOW_PROGRESS EXPECTED_MD5 "${gbafix_md5}")

            file(COPY "${GBA_TOOLCHAIN_LIST_DIR}/cmake/GbaFixCMakeLists.cmake" DESTINATION "${GBA_TOOLCHAIN_TOOLS}/gbafix")
            file(RENAME "${GBA_TOOLCHAIN_TOOLS}/gbafix/GbaFixCMakeLists.cmake" "${GBA_TOOLCHAIN_TOOLS}/gbafix/CMakeLists.txt")
            file(MAKE_DIRECTORY "${GBA_TOOLCHAIN_TOOLS}/gbafix/build")

            # Configure gbafix
            execute_process(
                COMMAND ${CMAKE_COMMAND} .. -DCMAKE_INSTALL_PREFIX=..
                WORKING_DIRECTORY "${GBA_TOOLCHAIN_TOOLS}/gbafix/build"
                RESULT_VARIABLE cmakeResult
            )
            if(NOT ${cmakeResult} EQUAL 0)
                message(FATAL_ERROR "CMake configure failed for gbafix (code ${cmakeResult})")
            endif()

            # Build gbafix
            execute_process(
                COMMAND ${CMAKE_COMMAND} --build . --target install
                WORKING_DIRECTORY "${GBA_TOOLCHAIN_TOOLS}/gbafix/build"
                RESULT_VARIABLE cmakeResult
            )
            if(NOT ${cmakeResult} EQUAL 0)
                message(FATAL_ERROR "CMake build failed for gbafix (code ${cmakeResult})")
            endif()

            # Clean up gbafix build directory
            file(REMOVE_RECURSE "${GBA_TOOLCHAIN_TOOLS}/gbafix/build")

            find_program(gbafixBinary NAMES "gbafix" PATHS "${GBA_TOOLCHAIN_TOOLS}/gbafix")
            set(GBAFIX "${gbafixBinary}" CACHE PATH "Path to gbafix binary" FORCE)
        endif()
    endif()
endfunction()

#! _gba_find_nedcmake : Locate and download nedclib
#
# nedcmake is used by gba_target_objcopy to generate e-reader dot codes
# If it is not available, it is downloaded from the nedclib URL in dependencies.ini
# The path to the nedcmake binary is stored in NEDCMAKE
#
function(_gba_find_nedcmake)
    if(NOT EXISTS "${NEDCMAKE}")
        # Searches:
        #   Environment Path
        #   Windows %LocalAppData%
        #   *NIX opt/local/
        #   GBA_TOOLCHAIN_TOOLS/tools
        set(searchPaths $ENV{Path})
        list(APPEND searchPaths "${HOST_LOCAL_DIRECTORY}")
        list(APPEND searchPaths "${GBA_TOOLCHAIN_TOOLS}/nedclib")

        # Test for nedcmake
        find_program(nedcmakeBinary NAMES "nedcmake" PATHS ${searchPaths})
        if(nedcmakeBinary)
            # Update cached entry
            set(NEDCMAKE "${nedcmakeBinary}" CACHE PATH "Path to nedcmake binary" FORCE)
        else()
            if(NOT EXISTS "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini")
                if(NOT DEPENDENCIES_URL)
                    message(FATAL_ERROR "Missing DEPENDENCIES_URL")
                endif()

                file(DOWNLOAD "${DEPENDENCIES_URL}" "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini" SHOW_PROGRESS)
            endif()

            file(READ "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini" iniFile)
            _ini_read_section("${iniFile}" "nedclib" nedclib)

            get_filename_component(ARM_GNU_TOOLCHAIN "${HOST_LOCAL_DIRECTORY}/arm-gnu-toolchain" ABSOLUTE)
            message(STATUS "Downloading nedclib from \"${nedclib_url}\" to \"${GBA_TOOLCHAIN_TOOLS}/nedclib\"")
            _gba_download("${nedclib_url}" "${GBA_TOOLCHAIN_TOOLS}/nedclib" SHOW_PROGRESS EXPECTED_MD5 "${nedclib_md5}")

            file(COPY "${GBA_TOOLCHAIN_LIST_DIR}/cmake/NedcmakeCMakeLists.cmake" DESTINATION "${GBA_TOOLCHAIN_TOOLS}/nedclib")
            file(RENAME "${GBA_TOOLCHAIN_TOOLS}/nedclib/NedcmakeCMakeLists.cmake" "${GBA_TOOLCHAIN_TOOLS}/nedclib/CMakeLists.txt")
            file(MAKE_DIRECTORY "${GBA_TOOLCHAIN_TOOLS}/nedclib/build")

            # Configure nedcmake
            execute_process(
                    COMMAND ${CMAKE_COMMAND} .. -DCMAKE_INSTALL_PREFIX=..
                    WORKING_DIRECTORY "${GBA_TOOLCHAIN_TOOLS}/nedclib/build"
                    RESULT_VARIABLE cmakeResult
            )
            if(NOT ${cmakeResult} EQUAL 0)
                message(FATAL_ERROR "CMake configure failed for nedcmake (code ${cmakeResult})")
            endif()

            # Build nedcmake
            execute_process(
                    COMMAND ${CMAKE_COMMAND} --build . --target install
                    WORKING_DIRECTORY "${GBA_TOOLCHAIN_TOOLS}/nedclib/build"
                    RESULT_VARIABLE cmakeResult
            )
            if(NOT ${cmakeResult} EQUAL 0)
                message(FATAL_ERROR "CMake build failed for nedcmake (code ${cmakeResult})")
            endif()

            # Clean up nedclib build directory
            file(REMOVE_RECURSE "${GBA_TOOLCHAIN_TOOLS}/nedclib/build")

            find_program(nedcmakeBinary NAMES "nedcmake" PATHS "${GBA_TOOLCHAIN_TOOLS}/nedclib")
            set(NEDCMAKE "${nedcmakeBinary}" CACHE PATH "Path to nedcmake binary" FORCE)
        endif()
    endif()
endfunction()

#! _gba_find_gbfs : Locate and download gbfs
#
# gbfs is used by gba_add_gbfs to compile assets into a .gbfs archive
# If it is not available, it is downloaded from the gbfs URL in dependencies.ini
# The path to the gbfs binary is stored in GBFS
#
function(_gba_find_gbfs)
    if(NOT EXISTS "${GBFS}" OR NOT EXISTS "${BIN2S}" OR NOT EXISTS "${PADBIN}")
        # Searches:
        #   Environment Path
        #   Windows %LocalAppData%
        #   *NIX opt/local/
        #   GBA_TOOLCHAIN_TOOLS/tools
        set(searchPaths $ENV{Path})
        list(APPEND searchPaths "${HOST_LOCAL_DIRECTORY}")
        list(APPEND searchPaths "${GBA_TOOLCHAIN_TOOLS}/gbfs")

        # Test for gbfs and bin2s
        find_program(gbfsBinary NAMES "gbfs" PATHS ${searchPaths})
        find_program(bin2sBinary NAMES "bin2s" PATHS ${searchPaths})
        find_program(padbinBinary NAMES "padbin" PATHS ${searchPaths})
        if(gbfsBinary AND bin2sBinary AND padbinBinary)
            # Update cached entry
            set(GBFS "${gbfsBinary}" CACHE PATH "Path to gbfs binary" FORCE)
            set(BIN2S "${bin2sBinary}" CACHE PATH "Path to bin2s binary" FORCE)
            set(PADBIN "${padbinBinary}" CACHE PATH "Path to padbin binary" FORCE)
        else()
            if(NOT EXISTS "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini")
                if(NOT DEPENDENCIES_URL)
                    message(FATAL_ERROR "Missing DEPENDENCIES_URL")
                endif()

                file(DOWNLOAD "${DEPENDENCIES_URL}" "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini" SHOW_PROGRESS)
            endif()

            file(READ "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini" iniFile)
            _ini_read_section("${iniFile}" "gbfs" gbfs)

            get_filename_component(ARM_GNU_TOOLCHAIN "${HOST_LOCAL_DIRECTORY}/arm-gnu-toolchain" ABSOLUTE)
            message(STATUS "Downloading gbfs from \"${gbfs_url}\" to \"${GBA_TOOLCHAIN_TOOLS}/gbfs\"")
            _gba_download("${gbfs_url}" "${GBA_TOOLCHAIN_TOOLS}/gbfs" SHOW_PROGRESS)

            file(COPY "${GBA_TOOLCHAIN_LIST_DIR}/cmake/GbfsCMakeLists.cmake" DESTINATION "${GBA_TOOLCHAIN_TOOLS}/gbfs")
            file(RENAME "${GBA_TOOLCHAIN_TOOLS}/gbfs/GbfsCMakeLists.cmake" "${GBA_TOOLCHAIN_TOOLS}/gbfs/CMakeLists.txt")
            file(MAKE_DIRECTORY "${GBA_TOOLCHAIN_TOOLS}/gbfs/build")

            # Configure gbfs
            execute_process(
                COMMAND ${CMAKE_COMMAND} .. -DCMAKE_INSTALL_PREFIX=..
                WORKING_DIRECTORY "${GBA_TOOLCHAIN_TOOLS}/gbfs/build"
                RESULT_VARIABLE cmakeResult
            )
            if(NOT ${cmakeResult} EQUAL 0)
                message(FATAL_ERROR "CMake configure failed for gbfs (code ${cmakeResult})")
            endif()

            # Build gbfs
            execute_process(
                COMMAND ${CMAKE_COMMAND} --build . --target install
                WORKING_DIRECTORY "${GBA_TOOLCHAIN_TOOLS}/gbfs/build"
                RESULT_VARIABLE cmakeResult
            )
            if(NOT ${cmakeResult} EQUAL 0)
                message(FATAL_ERROR "CMake build failed for gbfs (code ${cmakeResult})")
            endif()

            # Clean up gbfs build directory
            file(REMOVE_RECURSE "${GBA_TOOLCHAIN_TOOLS}/gbfs/build")

            find_program(gbfsBinary NAMES "gbfs" PATHS "${GBA_TOOLCHAIN_TOOLS}/gbfs")
            set(GBFS "${gbfsBinary}" CACHE PATH "Path to gbfs binary" FORCE)

            find_program(bin2sBinary NAMES "bin2s" PATHS "${GBA_TOOLCHAIN_TOOLS}/gbfs")
            set(BIN2S "${bin2sBinary}" CACHE PATH "Path to bin2s binary" FORCE)

            find_program(padbinBinary NAMES "padbin" PATHS "${GBA_TOOLCHAIN_TOOLS}/gbfs")
            set(PADBIN "${padbinBinary}" CACHE PATH "Path to padbin binary" FORCE)

            # Copy GBFS GBA library to /lib
            file(COPY
                "${GBA_TOOLCHAIN_TOOLS}/gbfs/libgbfs.c"
                "${GBA_TOOLCHAIN_TOOLS}/gbfs/CMakeLists.txt"
                DESTINATION "${GBA_TOOLCHAIN_LIST_DIR}/lib/gbfs"
            )
            file(COPY
                "${GBA_TOOLCHAIN_TOOLS}/gbfs/gbfs.h"
                DESTINATION "${GBA_TOOLCHAIN_LIST_DIR}/lib/gbfs/include"
            )
        endif()
    endif()
endfunction()
