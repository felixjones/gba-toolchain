#===============================================================================
#
# Binary file to object tool
#
# Script usage:
#   `cmake -P /path/to/Bin2o.cmake -- <output-file> [HEADER <header-file>] [ALIGNMENT <byte-alignment>] [PREFIX <symbol-prefix>] [SUFFIX_START <start-symbol-suffix>] [SUFFIX_END <end-symbol-suffix>] [SUFFIX_SIZE <size-symbol-suffix>] [NAME_WE] [ERROR_QUIET] <input-files>...`
#
# CMake usage:
#   `bin2o(<output-file> [HEADER <header-file>] [ALIGNMENT <byte-alignment>] [PREFIX <symbol-prefix>] [SUFFIX_START <start-symbol-suffix>] [SUFFIX_END <end-symbol-suffix>] [SUFFIX_SIZE <size-symbol-suffix>] [NAME_WE] [ERROR_QUIET] <input-files>...)`
#
# `HEADER` corresponding header file output name.
# `ALIGNMENT` byte alignment of each input (default 4).
# `PREFIX` prefix for all symbols.
# `SUFFIX_START` suffix for the start symbols.
# `SUFFIX_END` suffix for the end symbols (default "_end").
# `SUFFIX_SIZE` suffix for the size symbols (default "_len").
# `NAME_WE` remove longest extension from symbols.
# `ERROR_QUIET` ignore missing files.
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

function(bin2o output)
    set(options NAME_WE ERROR_QUIET)
    set(oneValueArgs HEADER ALIGNMENT PREFIX SUFFIX_START SUFFIX_END SUFFIX_SIZE)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "" ${ARGN})

    if(NOT ARGS_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Bin2o.cmake requires input files.")
    endif()

    if(NOT ARGS_ALIGNMENT)
        set(ARGS_ALIGNMENT 4)
    endif()
    if(NOT ARGS_SUFFIX_END)
        set(ARGS_SUFFIX_END "_end")
    endif()
    if(NOT ARGS_SUFFIX_SIZE)
        set(ARGS_SUFFIX_SIZE "_len")
    endif()

    if(ARGS_HEADER)
        string(APPEND headerContents [=[
/* Generated by Bin2o.cmake */
#pragma once

#if __cplusplus >= 201703L
#   include <cstddef>
#elif __cplusplus >= 201103L
#   include <cstddef>
#   include <cstdint>
#else
#   include <stddef.h>
#   include <stdint.h>
#endif

#if __cplusplus
extern "C" {
#endif
]=])
    endif()

    get_filename_component(cwd "." ABSOLUTE)
    string(REPLACE "/" ";" cwdComponents "${cwd}")
    list(LENGTH cwdComponents cwdComponentsLength)

    function(__bin2o_get_symbol_name resultSymbol inputPath)
        string(REPLACE "/" ";" inputComponents "${inputPath}")

        list(LENGTH inputComponents inputComponentsLength)
        if(${cwdComponentsLength} VERSION_LESS ${inputComponentsLength})
            set(minLength ${cwdComponentsLength})
        else()
            set(minLength ${inputComponentsLength})
        endif()
        math(EXPR minLength "${minLength} - 1")

        unset(symbolName)
        foreach(i RANGE ${minLength})
            list(GET cwdComponents ${i} component1)
            list(GET inputComponents ${i} component2)
            if(NOT "${component1}" STREQUAL "${component2}")
                break()
            endif()
            list(APPEND symbolName ${component1})
        endforeach()
        list(LENGTH symbolName symbolNameLength)
        list(SUBLIST inputComponents ${symbolNameLength} -1 symbolComponents)

        string(REGEX REPLACE "[^a-zA-Z0-9_;]" "_" symbol "${symbolComponents}")
        if("${symbol}" MATCHES "^[0-9]")
            set(${resultSymbol} "_${symbol}" PARENT_SCOPE)
        else()
            set(${resultSymbol} "${symbol}" PARENT_SCOPE)
        endif()
    endfunction()

    list(REMOVE_DUPLICATES ARGS_UNPARSED_ARGUMENTS)
    foreach(input ${ARGS_UNPARSED_ARGUMENTS})
        if(ARGS_ERROR_QUIET AND NOT EXISTS "${input}")
            continue()
        endif()

        if(NOT EXISTS "${input}")
            if(NOT IS_ABSOLUTE "${input}" AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${input}")
                set(input "${CMAKE_CURRENT_SOURCE_DIR}/${input}")
            else()
                message(FATAL_ERROR "Cannot find ${input}")
            endif()
        endif()

        string(REGEX REPLACE "[^a-zA-Z0-9_;]" "_" inputSymbolName "${input}")
        if(ARGS_NAME_WE)
            get_filename_component(inputWe "${input}" NAME_WE)
            __bin2o_get_symbol_name(symbolName "${inputWe}")
        else()
            __bin2o_get_symbol_name(symbolName "${input}")
        endif()

        list(APPEND inputs "${input}")

        list(APPEND objcopyRenames
                "_binary_${inputSymbolName}_start=${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_START}"
                "_binary_${inputSymbolName}_end=${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_END}"
                "_binary_${inputSymbolName}_size=${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_SIZE}"
        )

        if(ARGS_HEADER)
            file(SIZE "${input}" inputSize)

            string(APPEND headerContents "\n/* ${input} */\n")
            string(APPEND headerContents "#if __cplusplus >= 201703L\n")
            string(APPEND headerContents "inline constexpr std::size_t ${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_SIZE} = ${inputSize};\n")
            string(APPEND headerContents "extern const std::byte ${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_START}[];\n")
            string(APPEND headerContents "extern const std::byte ${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_END}[];\n")
            string(APPEND headerContents "#elif __cplusplus >= 201103L\n")
            string(APPEND headerContents "inline constexpr std::size_t ${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_SIZE} = ${inputSize};\n")
            string(APPEND headerContents "extern const std::uint8_t ${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_START}[];\n")
            string(APPEND headerContents "extern const std::uint8_t ${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_END}[];\n")
            string(APPEND headerContents "#else\n")
            string(APPEND headerContents "#\tdefine ${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_SIZE} ((size_t) ${inputSize})\n")
            string(APPEND headerContents "extern const uint8_t ${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_START}[];\n")
            string(APPEND headerContents "extern const uint8_t ${ARGS_PREFIX}${symbolName}${ARGS_SUFFIX_END}[];\n")
            string(APPEND headerContents "#endif\n\n")
        endif()
    endforeach()


    if(ARGS_HEADER)
        string(APPEND headerContents [=[
#if __cplusplus
} /* extern "C" */
#endif
]=])
    endif()

    execute_process(
            COMMAND "${CMAKE_LINKER}" -r -b binary -o "${output}" ${inputs}
            COMMAND "${CMAKE_OBJCOPY}" "${output}"
    )

    foreach(rename ${objcopyRenames})
        execute_process(COMMAND "${CMAKE_OBJCOPY}" --redefine-sym ${rename} "${output}")
    endforeach()

    execute_process(COMMAND "${CMAKE_OBJCOPY}" --set-section-alignment .data=${ARGS_ALIGNMENT} "${output}")
    execute_process(COMMAND "${CMAKE_OBJCOPY}" --rename-section .data=.rodata,alloc,load,readonly,data,contents "${output}")

    if(ARGS_HEADER)
        file(WRITE "${ARGS_HEADER}" "${headerContents}")
    endif()
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
    bin2o(${SCRIPT_ARGN})
else()
    set(BIN2O_PATH "${CMAKE_CURRENT_LIST_FILE}")
endif()
