#===============================================================================
#
# CMake toolchain file
#   Use with `--toolchain=/path/to/gba.toolchain.cmake`
#   Arm compiler tools are required
#   Using this toolchain file will enable several CMake modules within `/Modules`
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}" "${CMAKE_CURRENT_LIST_DIR}/Modules")

set(CMAKE_SYSTEM_NAME AdvancedGameBoy CACHE INTERNAL "")
set(CMAKE_SYSTEM_VERSION 1 CACHE INTERNAL "")
set(CMAKE_SYSTEM_PROCESSOR armv4t CACHE INTERNAL "")

if(CMAKE_HOST_SYSTEM_NAME MATCHES "Windows")
    if(CMAKE_GENERATOR MATCHES "Visual Studio")
        message(FATAL_ERROR "Toolchain is not compatible with Visual Studio (Use -G \"Ninja\" or -G \"Unix Makefiles\")")
    endif()

    if(CMAKE_GENERATOR STREQUAL "NMake Makefiles")
        message(FATAL_ERROR "Toolchain is not compatible with NMake (Use -G \"Ninja\" or -G \"Unix Makefiles\")")
    endif()

    # Fixup devkitPro default environment paths for Windows
    # This is not guaranteed to produce a correct path for devkitPro
    string(REGEX REPLACE "^/opt/" "C:/" DEVKITPRO "$ENV{DEVKITPRO}")
    string(REGEX REPLACE "^/opt/" "C:/" DEVKITARM "$ENV{DEVKITARM}")
    set(ENV{DEVKITPRO} "${DEVKITPRO}")
    set(ENV{DEVKITARM} "${DEVKITARM}")
    unset(DEVKITPRO)
    unset(DEVKITARM)

    # Find default install path for Arm GNU Toolchain
    unset(programfiles)
    foreach(v "ProgramW6432" "ProgramFiles" "ProgramFiles(x86)")
        if(DEFINED "ENV{${v}}")
            file(TO_CMAKE_PATH "$ENV{${v}}" envProgramfiles)
            list(APPEND programfiles "$envProgramfiles}")
            unset(envProgramfiles)
        endif()
    endforeach()

    if(DEFINED "ENV{SystemDrive}")
        foreach(d "Program Files" "Program Files (x86)")
            if(EXISTS "$ENV{SystemDrive}/${d}")
                list(APPEND programfiles "$ENV{SystemDrive}/${d}")
            endif()
        endforeach()
    endif()

    if(programfiles)
        list(REMOVE_DUPLICATES programfiles)
        find_path(GNUARM "Arm GNU Toolchain arm-none-eabi" PATHS ${programfiles})
        unset(programfiles)
    endif()
    
    if(GNUARM)
        file(GLOB GNUARM "${GNUARM}/Arm GNU Toolchain arm-none-eabi/*")
    endif()
endif()

if(CMAKE_HOST_SYSTEM_NAME MATCHES "Darwin")
    find_path(GNUARM "ArmGNUToolchain" PATHS "/Applications")
    
    if(GNUARM)
        file(GLOB GNUARM "${GNUARM}/ArmGNUToolchain/*/arm-none-eabi")
    endif()
endif()

# Fixup MSYS search paths
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "MSYS")
    # Disallow msys2 CMake
    if(CMAKE_COMMAND MATCHES "msys2")
        message(FATAL_ERROR "${CMAKE_COMMAND} is known to cause problems. Please use an alternative CMake executable.")
    endif()

    if(DEFINED "ENV{GNUARM}")
        execute_process(COMMAND cygpath -u "$ENV{GNUARM}" OUTPUT_VARIABLE GNUARM OUTPUT_STRIP_TRAILING_WHITESPACE)
        set(ENV{GNUARM} "${GNUARM}")
        unset(GNUARM)
    endif()

    if(DEFINED "ENV{DEVKITPRO}")
        execute_process(COMMAND cygpath -u "$ENV{DEVKITPRO}" OUTPUT_VARIABLE DEVKITPRO OUTPUT_STRIP_TRAILING_WHITESPACE)
        set(ENV{DEVKITPRO} "${DEVKITPRO}")
        unset(DEVKITPRO)
    endif()

    if(DEFINED "ENV{DEVKITARM}")
        execute_process(COMMAND cygpath -u "$ENV{DEVKITARM}" OUTPUT_VARIABLE DEVKITARM OUTPUT_STRIP_TRAILING_WHITESPACE)
        set(ENV{DEVKITARM} "${DEVKITARM}")
        unset(DEVKITARM)
    endif()
endif()

if(GNUARM)
    list(SORT GNUARM COMPARE NATURAL ORDER DESCENDING)
    list(POP_FRONT GNUARM GNUARM_LATEST)
endif()
unset(GNUARM CACHE)
if(GNUARM_LATEST)
    set(ENV{GNUARM} "${GNUARM_LATEST}")
    unset(GNUARM_LATEST)
endif()

set(COMPILER_SEARCH_PATHS "$ENV{GNUARM}" "$ENV{DEVKITARM}" "$ENV{DEVKITPRO}/devkitARM")

# Set library prefixes and suffixes
if(NOT CMAKE_FIND_LIBRARY_PREFIXES OR NOT CMAKE_FIND_LIBRARY_SUFFIXES)
    set(CMAKE_FIND_LIBRARY_PREFIXES "lib" CACHE INTERNAL "")
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".so" ".a" CACHE INTERNAL "")
endif()

# Set CMAKE_MAKE_PROGRAM for Unix Makefiles
if(CMAKE_GENERATOR STREQUAL "Unix Makefiles" AND NOT CMAKE_MAKE_PROGRAM)
    find_program(CMAKE_MAKE_PROGRAM NAMES make mingw32-make gmake)

    # DEVKITPRO sometimes has make
    if(NOT CMAKE_MAKE_PROGRAM)
        find_program(CMAKE_MAKE_PROGRAM NAMES make PATHS "$ENV{DEVKITPRO}/msys2/usr" PATH_SUFFIXES bin REQUIRED)
    endif()
endif()

# TODO: Set up linker to allow executable test compile
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY CACHE INTERNAL "")

function(find_arm_compiler lang binary)
    # Detects clang, clang++, gcc, g++
    macro(detect_compiler_id)
        set(COMPILER_BASENAME "${CMAKE_${lang}_COMPILER}")

        if(COMPILER_BASENAME MATCHES "($|[^a-zA-Z])((clang)|(clang\\+\\+))")
            set(CMAKE_${lang}_COMPILER_ID Clang CACHE INTERNAL "")
        elseif(COMPILER_BASENAME MATCHES "($|[^a-zA-Z])((gcc)|(g\\+\\+))")
            set(CMAKE_${lang}_COMPILER_ID GNU CACHE INTERNAL "")
        else()
            message(FATAL_ERROR "Unknown compiler ${CMAKE_${lang}_COMPILER}")
        endif()

        execute_process(COMMAND "${CMAKE_${lang}_COMPILER}" -dumpversion OUTPUT_VARIABLE version OUTPUT_STRIP_TRAILING_WHITESPACE)
        set(CMAKE_${lang}_COMPILER_VERSION "${version}" CACHE INTERNAL "")
        set(CMAKE_${lang}_COMPILER_FORCED ON CACHE INTERNAL "")
    endmacro()

    if(CMAKE_${lang}_COMPILER)
        detect_compiler_id()

        # Make sure compiler is ARM capable
        if(CMAKE_${lang}_COMPILER_ID MATCHES "Clang")
            execute_process(COMMAND ${CMAKE_${lang}_COMPILER} -print-targets OUTPUT_VARIABLE TARGETS OUTPUT_STRIP_TRAILING_WHITESPACE)

            if(NOT TARGETS MATCHES "arm[ \t\r\n]*")
                unset(CMAKE_${lang}_COMPILER CACHE)
            endif()
        elseif(CMAKE_${lang}_COMPILER_ID MATCHES "GNU")
            execute_process(COMMAND ${CMAKE_${lang}_COMPILER} -dumpmachine OUTPUT_VARIABLE DUMP OUTPUT_STRIP_TRAILING_WHITESPACE)

            if(NOT DUMP MATCHES "arm\\-none\\-eabi")
                unset(CMAKE_${lang}_COMPILER CACHE)
            endif()
        endif()
    endif()

    if(NOT CMAKE_${lang}_COMPILER)
        find_program(CMAKE_${lang}_COMPILER NAMES ${binary} PATHS ${COMPILER_SEARCH_PATHS} PATH_SUFFIXES bin REQUIRED)
    endif()

    detect_compiler_id()
endfunction()

find_arm_compiler(ASM arm-none-eabi-gcc) # Use GCC for ASM (solves compiler flag woes for GNU AS)
find_arm_compiler(C arm-none-eabi-gcc)
find_arm_compiler(CXX arm-none-eabi-g++)

# Set compiler target triples
set(CMAKE_ASM_COMPILER_TARGET arm-none-eabi CACHE INTERNAL "")
set(CMAKE_C_COMPILER_TARGET arm-none-eabi CACHE INTERNAL "")
set(CMAKE_CXX_COMPILER_TARGET arm-none-eabi CACHE INTERNAL "")

# Find linker
find_program(CMAKE_LINKER NAMES arm-none-eabi-ld PATHS ${COMPILER_SEARCH_PATHS} PATH_SUFFIXES bin REQUIRED)

# Find C compiler in sysroot
find_program(SYSROOT_COMPILER NAMES arm-none-eabi-gcc PATHS ${COMPILER_SEARCH_PATHS} PATH_SUFFIXES bin REQUIRED NO_CACHE)
unset(COMPILER_SEARCH_PATHS)

# Find sysroot top-level directory
get_filename_component(SYSROOT_COMPILER "${SYSROOT_COMPILER}" DIRECTORY)
if(SYSROOT_COMPILER MATCHES "/bin/?$")
    get_filename_component(SYSROOT_COMPILER "${SYSROOT_COMPILER}" DIRECTORY)
endif()
find_path(SYSROOT_DIRECTORY arm-none-eabi PATHS "${SYSROOT_COMPILER}" PATH_SUFFIXES lib REQUIRED)
unset(SYSROOT_COMPILER)

# Check for nano libs
execute_process(COMMAND "${CMAKE_C_COMPILER}" -dumpversion OUTPUT_VARIABLE LIBGCC_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
find_path(LIBGCC_DIRECTORY "gcc/arm-none-eabi/${LIBGCC_VERSION}" PATHS "${SYSROOT_DIRECTORY}" PATH_SUFFIXES lib)
find_library(CMAKE_NANO c_nano g_nano stdc++_nano supc++_nano PATHS "${LIBGCC_DIRECTORY}/gcc/arm-none-eabi/${LIBGCC_VERSION}")
if(CMAKE_NANO)
    set(CMAKE_NANO ON CACHE INTERNAL "")
else()
    set(CMAKE_NANO OFF CACHE INTERNAL "")
endif()
unset(LIBGCC_VERSION)
unset(LIBGCC_DIRECTORY CACHE)

set(CMAKE_SYSROOT "${SYSROOT_DIRECTORY}/arm-none-eabi" CACHE INTERNAL "")
unset(SYSROOT_DIRECTORY CACHE)

# Set __DEVKITARM__ macro
execute_process(COMMAND "${CMAKE_C_COMPILER}" --version OUTPUT_VARIABLE GNU_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
if(GNU_VERSION MATCHES "devkitARM")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__DEVKITARM__")
endif()
execute_process(COMMAND "${CMAKE_CXX_COMPILER}" --version OUTPUT_VARIABLE GNU_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
if(GNU_VERSION MATCHES "devkitARM")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D__DEVKITARM__")
endif()
unset(GNU_VERSION)

# Setup default linker flags
execute_process(COMMAND "${CMAKE_LINKER}" --help OUTPUT_VARIABLE LD_FLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
if(LD_FLAGS MATCHES "[-][-]no[-]warn[-]rwx[-]segments")
    set(CMAKE_EXE_LINKER_FLAGS "-Wl,--no-warn-rwx-segments -nostartfiles" CACHE INTERNAL "")
else()
    set(CMAKE_EXE_LINKER_FLAGS "-nostartfiles" CACHE INTERNAL "")
endif()
unset(LD_FLAGS)

# Set system prefix path
get_filename_component(CMAKE_SYSTEM_PREFIX_PATH "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY CACHE)
set(CMAKE_SYSTEM_LIBRARY_PATH "${CMAKE_SYSTEM_PREFIX_PATH}/lib" CACHE INTERNAL "")
