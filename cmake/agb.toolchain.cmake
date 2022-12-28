cmake_minimum_required(VERSION 3.0)

if(AGB_TOOLCHAIN_INCLUDED)
    return()
endif(AGB_TOOLCHAIN_INCLUDED)
set(AGB_TOOLCHAIN_INCLUDED ON)

set(CMAKE_SYSTEM_NAME Generic CACHE INTERNAL "")
set(CMAKE_SYSTEM_VERSION 1 CACHE INTERNAL "")
set(CMAKE_SYSTEM_PROCESSOR armv4t CACHE INTERNAL "")

if(CMAKE_HOST_SYSTEM_NAME MATCHES "Windows")
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
        find_path(gnuArm "Arm GNU Toolchain arm-none-eabi" PATHS ${programfiles})
        unset(programfiles)
    endif()

    if(gnuArm)
        file(GLOB gnuArm "${gnuArm}/Arm GNU Toolchain arm-none-eabi/*")
    endif()
    if(gnuArm)
        list(SORT gnuArm COMPARE NATURAL ORDER DESCENDING)
        list(POP_FRONT gnuArm gnuArmLatest)
        unset(gnuArm)
    endif()
    if(gnuArmLatest)
        set(ENV{GNUARM} "${gnuArmLatest}")
        unset(gnuArmLatest)
    endif()
endif()

set(COMPILER_SEARCH_PATHS ENV GNUARM ENV DEVKITARM "$ENV{DEVKITPRO}/devkitARM")

# Set CMAKE_MAKE_PROGRAM for Unix Makefiles
if(CMAKE_GENERATOR STREQUAL "Unix Makefiles" AND NOT CMAKE_MAKE_PROGRAM)
    find_program(CMAKE_MAKE_PROGRAM NAMES make mingw32-make REQUIRED)
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

# Find C compiler in sysroot
find_program(SYSROOT_COMPILER NAMES arm-none-eabi-gcc PATHS ${COMPILER_SEARCH_PATHS} PATH_SUFFIXES bin REQUIRED NO_CACHE)
execute_process(COMMAND "${SYSROOT_COMPILER}" -dumpversion OUTPUT_VARIABLE SYSROOT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
unset(COMPILER_SEARCH_PATHS)

# Find sysroot top-level directory
get_filename_component(SYSROOT_COMPILER "${SYSROOT_COMPILER}" DIRECTORY)
if(SYSROOT_COMPILER MATCHES "/bin/?$")
    get_filename_component(SYSROOT_COMPILER "${SYSROOT_COMPILER}" DIRECTORY)
endif()
find_path(SYSROOT_DIRECTORY arm-none-eabi PATHS "${SYSROOT_COMPILER}" PATH_SUFFIXES lib REQUIRED)
unset(SYSROOT_COMPILER)

set(CMAKE_SYSROOT "${SYSROOT_DIRECTORY}/arm-none-eabi" CACHE INTERNAL "")
unset(SYSROOT_DIRECTORY CACHE)

# Set standard include directories
set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES "${CMAKE_SYSROOT}/include" CACHE INTERNAL "")
set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES "${CMAKE_SYSROOT}/include/c++/${SYSROOT_VERSION};${CMAKE_SYSROOT}/include/c++/${SYSROOT_VERSION}/arm-none-eabi/thumb" CACHE INTERNAL "") # TODO: Support using arm include for -marm sources

# Set standard library search paths
find_path(LIBRARY_PATH "libc.a" PATHS "${CMAKE_SYSROOT}" PATH_SUFFIXES "lib/thumb/nofp" "lib/thumb" "lib")
if(LIBRARY_PATH)
    list(APPEND CMAKE_LIBRARY_PATH "${LIBRARY_PATH}")
    unset(LIBRARY_PATH CACHE)
endif()

# Set libgcc library search paths
find_path(LIBRARY_PATH "libgcc.a" PATHS "${CMAKE_SYSROOT}/../lib/gcc/arm-none-eabi/${SYSROOT_VERSION}" PATH_SUFFIXES "thumb/nofp" "thumb")
if(LIBRARY_PATH)
    list(APPEND CMAKE_LIBRARY_PATH "${LIBRARY_PATH}")
    unset(LIBRARY_PATH CACHE)
endif()

unset(SYSROOT_VERSION)

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
