#===============================================================================
#
# CMake toolchain configuration package for GNU Arm Embedded Toolchain
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

#! _find_arm_gnu : Locates ARM GNU toolchain
#
function(_find_arm_gnu)
    if(NOT EXISTS "${ARM_GNU_TOOLCHAIN}")
        # Searches:
        #   Environment Path
        #   Windows %LocalAppData%
        #   *NIX opt/local/
        #   GBA_TOOLCHAIN_LIST_DIR
        set(searchPaths $ENV{Path})
        list(APPEND searchPaths "${HOST_LOCAL_DIRECTORY}/arm-gnu-toolchain/bin")
        list(APPEND searchPaths "${GBA_TOOLCHAIN_LIST_DIR}/arm-gnu-toolchain/bin")

        # Test for gcc
        find_program(GNU_C_COMPILER NAMES "arm-none-eabi-gcc" PATHS ${searchPaths})
        if(GNU_C_COMPILER)
            get_filename_component(armGnuToolchain "${GNU_C_COMPILER}/../../" ABSOLUTE)

            # Update cached entry
            set(ARM_GNU_TOOLCHAIN "${armGnuToolchain}" CACHE PATH "Path to ARM GNU toolchain" FORCE)
        else()
            if(NOT EXISTS "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini")
                if(NOT DEPENDENCIES_URL)
                    message(FATAL_ERROR "Missing DEPENDENCIES_URL")
                endif()

                file(DOWNLOAD "${DEPENDENCIES_URL}" "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini" SHOW_PROGRESS)
            endif()

            file(READ "${GBA_TOOLCHAIN_LIST_DIR}/dependencies.ini" iniFile)
            _ini_read_section("${iniFile}" "gnu-arm-embedded-toolchain" gnuArmUrl)

            get_filename_component(armGnuToolchain "${HOST_LOCAL_DIRECTORY}/arm-gnu-toolchain" ABSOLUTE)
            if(NOT gnuArmUrl_${HOST_PLATFORM_NAME})
                message(FATAL_ERROR "Could not find ARM GNU url for ${HOST_PLATFORM_NAME}")
            endif()
            message(STATUS "Downloading ARM GNU toolchain from \"${gnuArmUrl_${HOST_PLATFORM_NAME}}\" to \"${armGnuToolchain}\"")
            _gba_download("${gnuArmUrl_${HOST_PLATFORM_NAME}}" "${armGnuToolchain}" SHOW_PROGRESS EXPECTED_MD5 "${gnuArmUrl_${HOST_PLATFORM_NAME}-md5}")

            set(ARM_GNU_TOOLCHAIN "${armGnuToolchain}" CACHE PATH "Path to ARM GNU toolchain" FORCE)

            _ini_read_section("${iniFile}" "arm-none-eabi-gdb" gdbUrl)
            if(gdbUrl_${HOST_PLATFORM_NAME})
                find_program(gdbBinary NAMES "arm-none-eabi-gdb" PATHS "${armGnuToolchain}/bin")
                execute_process(COMMAND "${gdbBinary}" -v OUTPUT_VARIABLE gdbVersion)

                if("${gdbVersion}" STREQUAL "")
                    get_filename_component(armGdb "${armGnuToolchain}/bin" ABSOLUTE)

                    message(STATUS "Downloading arm-none-eabi-gdb toolchain from \"${gdbUrl_${HOST_PLATFORM_NAME}}\" to \"${armGdb}\"")
                    _gba_download("${gdbUrl_${HOST_PLATFORM_NAME}}" "${armGdb}" SHOW_PROGRESS MERGE EXPECTED_MD5 "${gdbUrl_${HOST_PLATFORM_NAME}-md5}")
                endif()
            endif()
        endif()
    endif()

    # GCC was used to search for ARM_GNU_TOOLCHAIN, so we may have already found it
    if(NOT GNU_C_COMPILER)
        find_program(GNU_C_COMPILER NAMES "arm-none-eabi-gcc" PATHS "${ARM_GNU_TOOLCHAIN}/bin")
    endif()
    find_program(GNU_CXX_COMPILER NAMES "arm-none-eabi-g++" PATHS "${ARM_GNU_TOOLCHAIN}/bin")
    find_program(GNU_OBJCOPY NAMES "arm-none-eabi-objcopy" PATHS "${ARM_GNU_TOOLCHAIN}/bin")
    find_program(GNU_AR NAMES "arm-none-eabi-ar" PATHS "${ARM_GNU_TOOLCHAIN}/bin")
    find_program(GNU_RANLIB NAMES "arm-none-eabi-ranlib" PATHS "${ARM_GNU_TOOLCHAIN}/bin")
    find_program(GNU_NM NAMES "arm-none-eabi-nm" PATHS "${ARM_GNU_TOOLCHAIN}/bin")
    find_program(GNU_OBJDUMP NAMES "arm-none-eabi-objdump" PATHS "${ARM_GNU_TOOLCHAIN}/bin")
    find_program(GNU_STRIP NAMES "arm-none-eabi-strip" PATHS "${ARM_GNU_TOOLCHAIN}/bin")

    # Detect compiler versions
    execute_process(COMMAND "${GNU_C_COMPILER}" -dumpversion OUTPUT_VARIABLE GNU_C_COMPILER_VERSION)
    string(STRIP "${GNU_C_COMPILER_VERSION}" GNU_C_COMPILER_VERSION)
    set(GNU_C_COMPILER_VERSION ${GNU_C_COMPILER_VERSION} PARENT_SCOPE)

    execute_process(COMMAND "${GNU_CXX_COMPILER}" -dumpversion OUTPUT_VARIABLE GNU_CXX_COMPILER_VERSION)
    string(STRIP "${GNU_CXX_COMPILER_VERSION}" GNU_CXX_COMPILER_VERSION)
    set(GNU_CXX_COMPILER_VERSION ${GNU_CXX_COMPILER_VERSION} PARENT_SCOPE)
endfunction()

function(_find_devkitarm)
    find_program(GNU_C_COMPILER NAMES "arm-none-eabi-gcc" PATHS "$ENV{DEVKITARM}/bin")
    find_program(GNU_CXX_COMPILER NAMES "arm-none-eabi-g++" PATHS "$ENV{DEVKITARM}/bin")
    find_program(GNU_OBJCOPY NAMES "arm-none-eabi-objcopy" PATHS "$ENV{DEVKITARM}/bin")
    find_program(GNU_AR NAMES "arm-none-eabi-ar" PATHS "$ENV{DEVKITARM}/bin")
    find_program(GNU_RANLIB NAMES "arm-none-eabi-ranlib" PATHS "$ENV{DEVKITARM}/bin")
    find_program(GNU_NM NAMES "arm-none-eabi-nm" PATHS "$ENV{DEVKITARM}/bin")
    find_program(GNU_OBJDUMP NAMES "arm-none-eabi-objdump" PATHS "$ENV{DEVKITARM}/bin")
    find_program(GNU_STRIP NAMES "arm-none-eabi-strip" PATHS "$ENV{DEVKITARM}/bin")

    # Detect compiler versions
    execute_process(COMMAND "${GNU_C_COMPILER}" -dumpversion OUTPUT_VARIABLE GNU_C_COMPILER_VERSION)
    string(STRIP "${GNU_C_COMPILER_VERSION}" GNU_C_COMPILER_VERSION)
    set(GNU_C_COMPILER_VERSION ${GNU_C_COMPILER_VERSION} PARENT_SCOPE)

    execute_process(COMMAND "${GNU_CXX_COMPILER}" -dumpversion OUTPUT_VARIABLE GNU_CXX_COMPILER_VERSION)
    string(STRIP "${GNU_CXX_COMPILER_VERSION}" GNU_CXX_COMPILER_VERSION)
    set(GNU_CXX_COMPILER_VERSION ${GNU_CXX_COMPILER_VERSION} PARENT_SCOPE)
endfunction()

#! _find_clang : Locates Clang
#
function(_find_clang)
    find_program(CLANG_C_COMPILER NAMES "clang")
    find_program(CLANG_CXX_COMPILER NAMES "clang++")

    if(NOT CLANG_C_COMPILER)
        message(FATAL_ERROR "Unable to locate Clang compiler")
    endif()

    # Detect compiler versions
    execute_process(COMMAND "${CLANG_C_COMPILER}" -dumpversion OUTPUT_VARIABLE CLANG_C_COMPILER_VERSION)
    string(STRIP "${CLANG_C_COMPILER_VERSION}" CLANG_C_COMPILER_VERSION)
    set(CLANG_C_COMPILER_VERSION ${CLANG_C_COMPILER_VERSION} PARENT_SCOPE)

    execute_process(COMMAND "${CLANG_CXX_COMPILER}" -dumpversion OUTPUT_VARIABLE CLANG_CXX_COMPILER_VERSION)
    string(STRIP "${CLANG_CXX_COMPILER_VERSION}" CLANG_CXX_COMPILER_VERSION)
    set(CLANG_CXX_COMPILER_VERSION ${CLANG_CXX_COMPILER_VERSION} PARENT_SCOPE)
endfunction()

#! _configure_toolchain : Sets up CMake toolchain
#
function(_configure_toolchain)

    #====================
    # Docstrings
    #====================

    set(DOCSTRING_CMAKE_ASM_FLAGS               "Flags used by the Assembler compiler during all build types.")
    set(DOCSTRING_CMAKE_C_FLAGS                 "Flags used by the C compiler during all build types.")
    set(DOCSTRING_CMAKE_CXX_FLAGS               "Flags used by the C++ compiler during all build types.")
    set(DOCSTRING_CMAKE_C_FLAGS_MINSIZEREL      "Flags used by the C compiler during MINSIZEREL builds.")
    set(DOCSTRING_CMAKE_CXX_FLAGS_MINSIZEREL    "Flags used by the C++ compiler during MINSIZEREL builds.")
    set(DOCSTRING_CMAKE_C_FLAGS_DEBUG           "Flags used by the C compiler during DEBUG builds.")
    set(DOCSTRING_CMAKE_CXX_FLAGS_DEBUG         "Flags used by the C++ compiler during DEBUG builds.")
    set(DOCSTRING_CMAKE_C_COMPILER              "C compiler executable.")
    set(DOCSTRING_CMAKE_CXX_COMPILER            "C++ compiler executable.")
    set(DOCSTRING_CMAKE_ASM_COMPILER            "ASM compiler executable.")
    set(DOCSTRING_CMAKE_C_LINK_EXECUTABLE       "Executable used by the C linker.")
    set(DOCSTRING_CMAKE_CXX_LINK_EXECUTABLE     "Executable used by the C++ linker.")

    #====================
    # Compilers
    #====================

    # Flags for all build types
    set(SHARED_C_FLAGS "-mabi=aapcs -march=armv4t -mcpu=arm7tdmi")
    set(SHARED_CXX_FLAGS "-mabi=aapcs -march=armv4t -mcpu=arm7tdmi -fno-exceptions") # nano is not compiled with C++ exceptions
    set(SHARED_LINKER_FLAGS "-nostartfiles -mthumb") # Use libraries compiled for thumb (nofp)

    if(USE_CLANG)
        if(USE_DEVKITARM)
            set(toolchain $ENV{DEVKITARM})
        else()
            set(toolchain ${ARM_GNU_TOOLCHAIN})
        endif()

        if(USE_DEVKITARM)
            include_directories(SYSTEM
                ${toolchain}/arm-none-eabi/include/c++
                ${toolchain}/arm-none-eabi/include/c++/${GNU_CXX_COMPILER_VERSION}
                ${toolchain}/arm-none-eabi/include
                ${toolchain}/arm-none-eabi
            )
        else()
            include_directories(SYSTEM
                ${toolchain}/lib/gcc/arm-none-eabi/${GNU_C_COMPILER_VERSION}/include
                ${toolchain}/arm-none-eabi/include/c++/${GNU_CXX_COMPILER_VERSION}
                ${toolchain}/arm-none-eabi/include/c++/${GNU_CXX_COMPILER_VERSION}/arm-none-eabi
            )
        endif()

        # Flags for all build types
        set(CMAKE_C_FLAGS_INIT "${SHARED_C_FLAGS} --target=arm-arm-none-eabi -isystem \"${toolchain}/arm-none-eabi/include\"" CACHE STRING "${DOCSTRING_CMAKE_C_FLAGS}")
        set(CMAKE_CXX_FLAGS_INIT "${SHARED_CXX_FLAGS} --target=arm-arm-none-eabi -isystem \"${toolchain}/arm-none-eabi/include\"" CACHE STRING "${DOCSTRING_CMAKE_CXX_FLAGS}")

        # Flags for MinSizeRel
        set(CMAKE_C_FLAGS_MINSIZEREL_INIT "-Oz -DNDEBUG" CACHE STRING "${DOCSTRING_CMAKE_C_FLAGS_MINSIZEREL}")
        set(CMAKE_CXX_FLAGS_MINSIZEREL_INIT "-Oz -DNDEBUG" CACHE STRING "${DOCSTRING_CMAKE_CXX_FLAGS_MINSIZEREL}")

        # Use GNU compilers for Clang linking
        set(CMAKE_C_LINK_EXECUTABLE "\"${GNU_C_COMPILER}\" <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>" CACHE FILEPATH "${DOCSTRING_CMAKE_C_LINK_EXECUTABLE}")
        set(CMAKE_CXX_LINK_EXECUTABLE "\"${GNU_CXX_COMPILER}\" <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>" CACHE FILEPATH "${DOCSTRING_CMAKE_CXX_LINK_EXECUTABLE}")

        # Compilers
        set(CMAKE_C_COMPILER "${CLANG_C_COMPILER}" CACHE FILEPATH "${DOCSTRING_CMAKE_C_COMPILER}")
        set(CMAKE_CXX_COMPILER "${CLANG_CXX_COMPILER}" CACHE FILEPATH "${DOCSTRING_CMAKE_CXX_COMPILER}")
    else()
        # Flags for all build types
        set(CMAKE_C_FLAGS_INIT "${SHARED_C_FLAGS}" CACHE STRING "${DOCSTRING_CMAKE_C_FLAGS}")
        set(CMAKE_CXX_FLAGS_INIT "${SHARED_CXX_FLAGS}" CACHE STRING "${DOCSTRING_CMAKE_CXX_FLAGS}")

        # Compilers
        set(CMAKE_C_COMPILER "${GNU_C_COMPILER}" CACHE FILEPATH "${DOCSTRING_CMAKE_C_COMPILER}")
        set(CMAKE_CXX_COMPILER "${GNU_CXX_COMPILER}" CACHE FILEPATH "${DOCSTRING_CMAKE_CXX_COMPILER}")
    endif()

    # Flags for Debug
    set(CMAKE_C_FLAGS_DEBUG_INIT "-Og -g" CACHE STRING "${DOCSTRING_CMAKE_C_FLAGS_DEBUG}")
    set(CMAKE_CXX_FLAGS_DEBUG_INIT "-Og -g" CACHE STRING "${DOCSTRING_CMAKE_CXX_FLAGS_DEBUG}")

    # Assembler
    set(CMAKE_ASM_COMPILER "${GNU_C_COMPILER}" CACHE FILEPATH "${DOCSTRING_CMAKE_ASM_COMPILER}")

    #====================
    # objcopy ar ranlib nm objdump strip
    #====================

    set(CMAKE_OBJCOPY "${GNU_OBJCOPY}" CACHE FILEPATH "Path to objcopy.")
    set(CMAKE_AR "${GNU_AR}" CACHE FILEPATH "Path to ar.")
    set(CMAKE_RANLIB "${GNU_RANLIB}" CACHE FILEPATH "Path to ranlib.")
    set(CMAKE_NM "${GNU_NM}" CACHE FILEPATH "Path to nm.")
    set(CMAKE_OBJDUMP "${GNU_OBJDUMP}" CACHE FILEPATH "Path to objdump.")
    set(CMAKE_STRIP "${GNU_STRIP}" CACHE FILEPATH "Path to strip.")

    #====================
    # Linkers
    #====================

    if(USE_DEVKITARM)
        set(CMAKE_EXE_LINKER_FLAGS_INIT "${SHARED_LINKER_FLAGS}" CACHE INTERNAL "" FORCE)
    else()
        # Unfortunately ARM GNU toolchain compiles with short enums
        # This causes a 32-bit enum warning to be emitted, even if all binaries use 32-bit enums
        set(CMAKE_EXE_LINKER_FLAGS_INIT "${SHARED_LINKER_FLAGS} -Xlinker -no-enum-size-warning" CACHE INTERNAL "" FORCE)
    endif()

    set(CMAKE_LINKER "${GNU_C_COMPILER}" CACHE FILEPATH "Path to ld.")
    set(CMAKE_SHARED_LINKER "${GNU_C_COMPILER}" CACHE FILEPATH "Path to ld for shared linking.")
    set(CMAKE_STATIC_LINKER "${GNU_C_COMPILER}" CACHE FILEPATH "Path to ld for static linking.")

    #====================
    # Archivers
    #====================

    set(CMAKE_C_COMPILER_AR "${CMAKE_AR}" CACHE FILEPATH "Path to C ar.")
    set(CMAKE_C_COMPILER_RANLIB "${CMAKE_RANLIB}" CACHE FILEPATH "Path to C ranlib.")

    set(CMAKE_CXX_COMPILER_AR "${CMAKE_AR}" CACHE FILEPATH "Path to C++ ar.")
    set(CMAKE_CXX_COMPILER_RANLIB "${CMAKE_RANLIB}" CACHE FILEPATH "Path to C++ ranlib.")

endfunction()

#! _cpp : C pre-processor
#
# _input is text to be pre-processed and stored into variable _output
#
# \arg:_input Text to be pre-processed
# \arg:_output Output variable to store result
# \param:KEEP_COMMENTS Should comments be preserved? This may affect macro expansion.
# \param:DEFINES List of name=defintion macros
# \param:INCLUDE_DIRECTORIES List of additional search paths for includes
#
function(_cpp _input _output)
    set(options
        KEEP_COMMENTS
    )
    set(oneValueArgs)
    set(multiValueArgs
        DEFINES
        INCLUDE_DIRECTORIES
    )
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(ARGS_KEEP_COMMENTS)
        set(KEEP_COMMENTS -CC)
    endif()
    list(TRANSFORM ARGS_DEFINES PREPEND -D)
    list(TRANSFORM ARGS_INCLUDE_DIRECTORIES PREPEND -I)

    execute_process(
        COMMAND ${CMAKE_COMMAND} -E echo ${_input}
        COMMAND ${GNU_C_COMPILER} ${ARGS_DEFINES} ${ARGS_INCLUDE_DIRECTORIES} ${KEEP_COMMENTS} -undef -E -P -
        OUTPUT_VARIABLE output
    )

    set(${_output} ${output} PARENT_SCOPE)
endfunction()
