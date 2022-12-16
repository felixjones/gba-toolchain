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
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY" CACHE INTERNAL "")

function(find_arm_compiler lang binary)
    macro(detect_compiler_id)
        get_filename_component(COMPILER_BASENAME "${CMAKE_${lang}_COMPILER}" NAME)

        if(COMPILER_BASENAME MATCHES "(as)|(g(cc)|(\\+\\+))")
            set(CMAKE_${lang}_COMPILER_ID GNU CACHE INTERNAL "")
        elseif(COMPILER_BASENAME MATCHES "clang(\\+\\+)?")
            set(CMAKE_${lang}_COMPILER_ID Clang CACHE INTERNAL "")
        else()
            message(FATAL_ERROR "Unknown compiler ${CMAKE_${lang}_COMPILER}")
        endif()
    endmacro()

    if(CMAKE_${lang}_COMPILER)
        detect_compiler_id()

        if(CMAKE_${lang}_COMPILER_ID MATCHES Clang)
            execute_process(COMMAND ${CMAKE_${lang}_COMPILER} -print-targets OUTPUT_VARIABLE TARGETS OUTPUT_STRIP_TRAILING_WHITESPACE)

            if(NOT TARGETS MATCHES "arm[ \t\r\n]*")
                unset(CMAKE_${lang}_COMPILER CACHE)
            endif()
        elseif(CMAKE_${lang}_COMPILER_ID MATCHES GNU)
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
        find_program(CMAKE_${lang}_COMPILER NAMES ${binary} PATHS ENV DEVKITARM "$ENV{DEVKITPRO}/devkitARM" PATH_SUFFIXES "bin" REQUIRED)
    endif()

    detect_compiler_id()
endfunction()

find_arm_compiler(ASM arm-none-eabi-as)
find_arm_compiler(C arm-none-eabi-gcc)
find_arm_compiler(CXX arm-none-eabi-g++)

set(CMAKE_ASM_COMPILER_TARGET arm-none-eabi CACHE INTERNAL "")
set(CMAKE_C_COMPILER_TARGET arm-none-eabi CACHE INTERNAL "")
set(CMAKE_CXX_COMPILER_TARGET arm-none-eabi CACHE INTERNAL "")

execute_process(COMMAND ${CMAKE_C_COMPILER} -dumpversion OUTPUT_VARIABLE GCC_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)

# TODO: Try locate sysroot, this should be used to find the arm-none-eabi/thumb libraries and gcc/thumb libraries
get_filename_component(COMPILER_DIRECTORY "${CMAKE_ASM_COMPILER}" DIRECTORY)
if(COMPILER_DIRECTORY MATCHES "/bin/?$")
    get_filename_component(COMPILER_DIRECTORY "${COMPILER_DIRECTORY}" DIRECTORY)
endif()
set(CMAKE_FIND_ROOT_PATH "${COMPILER_DIRECTORY}/lib/arm-none-eabi" "${COMPILER_DIRECTORY}/lib/gcc/arm-none-eabi/${GCC_VERSION}" CACHE INTERNAL "")
unset(COMPILER_DIRECTORY)

if(USE_DEVKITARM)
    set(CMAKE_EXE_LINKER_FLAGS_INIT "${SHARED_LINKER_FLAGS}" CACHE INTERNAL "" FORCE)
else()
    # Unfortunately ARM GNU toolchain compiles with short enums
    # This causes a 32-bit enum warning to be emitted, even if all binaries use 32-bit enums
    set(CMAKE_EXE_LINKER_FLAGS_INIT "${SHARED_LINKER_FLAGS} -Xlinker -no-enum-size-warning" CACHE INTERNAL "" FORCE)
endif()
