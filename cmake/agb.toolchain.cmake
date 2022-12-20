cmake_minimum_required(VERSION 3.0)

if(AGB_TOOLCHAIN_INCLUDED)
    return()
endif(AGB_TOOLCHAIN_INCLUDED)
set(AGB_TOOLCHAIN_INCLUDED ON)

set(CMAKE_SYSTEM_NAME Generic CACHE INTERNAL "")
set(CMAKE_SYSTEM_VERSION AGB CACHE INTERNAL "")
set(CMAKE_SYSTEM_PROCESSOR arm CACHE INTERNAL "")

# Set CMAKE_MAKE_PROGRAM for Unix Makefiles
if(CMAKE_GENERATOR STREQUAL "Unix Makefiles" AND NOT CMAKE_MAKE_PROGRAM)
    find_program(CMAKE_MAKE_PROGRAM NAMES make mingw32-make REQUIRED)
endif()

# TODO: Set up linker to allow executable test compile
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY CACHE INTERNAL "")

function(find_arm_compiler lang binary)
    macro(detect_compiler_id)
        set(COMPILER_BASENAME "${CMAKE_${lang}_COMPILER}")

        if(COMPILER_BASENAME MATCHES "($|[^a-zA-Z])((clang)|(clang\\+\\+))")
            set(CMAKE_${lang}_COMPILER_ID Clang CACHE INTERNAL "")
        elseif(COMPILER_BASENAME MATCHES "($|[^a-zA-Z])((as)|(gcc)|(g\\+\\+))")
            set(CMAKE_${lang}_COMPILER_ID GNU CACHE INTERNAL "")
        else()
            message(FATAL_ERROR "Unknown compiler ${CMAKE_${lang}_COMPILER}")
        endif()
    endmacro()

    if(CMAKE_${lang}_COMPILER)
        detect_compiler_id()

        if(CMAKE_${lang}_COMPILER_ID MATCHES "Clang")
            execute_process(COMMAND ${CMAKE_${lang}_COMPILER} -print-targets OUTPUT_VARIABLE TARGETS OUTPUT_STRIP_TRAILING_WHITESPACE)

            if(NOT TARGETS MATCHES "arm[ \t\r\n]*")
                unset(CMAKE_${lang}_COMPILER CACHE)
            endif()
        elseif(CMAKE_${lang}_COMPILER_ID MATCHES "GNU")
            if(lang STREQUAL ASM)
                execute_process(COMMAND ${CMAKE_${lang}_COMPILER} --version OUTPUT_VARIABLE DUMP OUTPUT_STRIP_TRAILING_WHITESPACE)
            else()
                execute_process(COMMAND ${CMAKE_${lang}_COMPILER} -dumpmachine OUTPUT_VARIABLE DUMP OUTPUT_STRIP_TRAILING_WHITESPACE)
            endif()

            if(NOT DUMP MATCHES "arm\\-none\\-eabi")
                unset(CMAKE_${lang}_COMPILER CACHE)
            endif()
        endif()
    endif()

    if(NOT CMAKE_${lang}_COMPILER)
        # TODO: Maybe fix up the /opt/devkitPro path for Windows?
        find_program(CMAKE_${lang}_COMPILER NAMES ${binary} PATHS ENV DEVKITARM "$ENV{DEVKITPRO}/devkitARM" PATH_SUFFIXES bin REQUIRED)
    endif()

    detect_compiler_id()
endfunction()

find_arm_compiler(ASM arm-none-eabi-as)
find_arm_compiler(C arm-none-eabi-gcc)
find_arm_compiler(CXX arm-none-eabi-g++)

find_program(SYSROOT_COMPILER NAMES arm-none-eabi-gcc PATHS ENV DEVKITARM "$ENV{DEVKITPRO}/devkitARM" PATH_SUFFIXES bin REQUIRED)
execute_process(COMMAND "${SYSROOT_COMPILER}" -dumpversion OUTPUT_VARIABLE SYSROOT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)

# TODO: Try locate sysroot, this should be used to find the arm-none-eabi/thumb libraries and gcc/thumb libraries
get_filename_component(SYSROOT_DIRECTORY "${SYSROOT_COMPILER}" DIRECTORY)
unset(SYSROOT_COMPILER)
if(SYSROOT_DIRECTORY MATCHES "/bin/?$")
    get_filename_component(SYSROOT_DIRECTORY "${SYSROOT_DIRECTORY}" DIRECTORY)
endif()
find_path(SYSROOT_DIRECTORY arm-none-eabi PATHS "${SYSROOT_DIRECTORY}" PATH_SUFFIXES lib REQUIRED)
set(CMAKE_SYSROOT "${SYSROOT_DIRECTORY}/arm-none-eabi" CACHE INTERNAL "")
unset(SYSROOT_DIRECTORY)

set(CMAKE_ASM_COMPILER_TARGET arm-none-eabi CACHE INTERNAL "")
set(CMAKE_C_COMPILER_TARGET arm-none-eabi CACHE INTERNAL "")
set(CMAKE_CXX_COMPILER_TARGET arm-none-eabi CACHE INTERNAL "")

set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES "${CMAKE_SYSROOT}/include" CACHE INTERNAL "")
set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES "${CMAKE_SYSROOT}/include/c++/${SYSROOT_VERSION};${CMAKE_SYSROOT}/include/c++/${SYSROOT_VERSION}/arm-none-eabi/thumb" CACHE INTERNAL "") # TODO: Support using arm include for -marm sources

execute_process(COMMAND "${CMAKE_C_COMPILER}" --version OUTPUT_VARIABLE SYSROOT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
if(SYSROOT_VERSION MATCHES "devkitARM")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__DEVKITARM__")
endif()
execute_process(COMMAND "${CMAKE_CXX_COMPILER}" --version OUTPUT_VARIABLE SYSROOT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
if(SYSROOT_VERSION MATCHES "devkitARM")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D__DEVKITARM__")
endif()
unset(SYSROOT_VERSION)

#TODO: CMAKE_<LANG>_STANDARD_LIBRARIES for librom, libmultiboot, etc?
