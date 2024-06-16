#===============================================================================
#
# File splitting utility
#   Splits input file into multiple output files each with a given maximum length
#
# Script usage:
#   `cmake -P /path/to/FileSplit.cmake -- <input-file> [OUTPUT <output-file> LENGTH <bytes>]... [OUTPUT <output-file> [LENGTH <bytes>]]`
#
# CMake usage:
#   `file_split(<input-file> [OUTPUT <output-file> LENGTH <bytes>]... [OUTPUT <output-file> [LENGTH <bytes>]])`
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include("${CMAKE_CURRENT_LIST_DIR}/Hexdecode.cmake" OPTIONAL RESULT_VARIABLE HEXDECODE_INCLUDED)

function(file_split input)
    # Parse arguments
    set(output_length -1)
    foreach(arg ${ARGN})
        if(arg STREQUAL "OUTPUT")
            if(DEFINED output_file)
                list(APPEND files "${output_file}")
                list(APPEND lengths "${output_length}")
            endif()
            unset(output_file)
            set(output_length -1)
            set(state "state_output")
        elseif(arg STREQUAL "LENGTH")
            set(state "state_length")
        elseif(state STREQUAL "state_output")
            set(output_file "${arg}")
        elseif(state STREQUAL "state_length")
            set(output_length "${arg}")
        else()
            message(FATAL_ERROR "Invalid arguments. Check the argument list.")
        endif()
    endforeach()

    # add the last file
    if(DEFINED output_file)
        list(APPEND files ${output_file})
        list(APPEND lengths ${output_length})
    endif()

    # Split macros
    find_program(DD_EXECUTABLE NAMES dd)
    find_program(POWERSHELL_EXECUTABLE NAMES powershell pwsh)

    # Try if dd is available
    if(DD_EXECUTABLE)
        macro(do_split part length offset)
            if(${length} LESS 0)
                execute_process(
                        COMMAND "${DD_EXECUTABLE}" if=${input} of=${part} bs=1 skip=${offset}
                        ERROR_QUIET
                )
            else()
                execute_process(
                        COMMAND "${DD_EXECUTABLE}" if=${input} of=${part} bs=1 count=${length} skip=${offset}
                        ERROR_QUIET
                )
            endif()
        endmacro()
    elseif(POWERSHELL_EXECUTABLE)
        # Try if powershell is available
        macro(do_split part length offset)
            if(${length} LESS 0)
                execute_process(
                        COMMAND "${POWERSHELL_EXECUTABLE}" -Command "
                    & {
                        $bytes = [System.IO.File]::ReadAllBytes('${input}');
                        [System.IO.File]::WriteAllBytes('${part}', $bytes[${offset}..($bytes.Length - 1)])
                    }
                "
                )
            else()
                execute_process(
                        COMMAND "${POWERSHELL_EXECUTABLE}" -Command "
                    & {
                        $bytes = [System.IO.File]::ReadAllBytes('${input}');
                        $lengthMinusOne = ${length} - 1;
                        $lengthPlusOffset = $lengthMinusOne + ${offset};
                        $lengthArray = $bytes.Length - 1;
                        if ($lengthPlusOffset -lt $lengthArray) {
                            $newArray = $bytes[${offset}..$lengthPlusOffset];
                        } else {
                            $newArray = $bytes[${offset}..$lengthArray];
                        }
                        [System.IO.File]::WriteAllBytes('${part}', $newArray)
                    }
                "
                )
            endif()
        endmacro()
    elseif(HEXDECODE_INCLUDED)
        # Fallback to Hexdecode (SLOW!)
        file(READ "${input}" hexes HEX)
        string(LENGTH hexes hexesLength)

        macro(do_split part length offset)
            if(${length} GREATER 0)
                math(EXPR length2 "${length} * 2")
            else()
                set(length2 ${length})
            endif()
            math(EXPR offset2 "${offset} * 2")

            if(${offset2} LESS ${hexesLength})
                string(SUBSTRING "${hexes}" ${offset2} ${length2} partHex)
                hexdecode("${part}" ${partHex})
            else()
                file(TOUCH "${part}")
            endif()
        endmacro()
    else()
        message(FATAL_ERROR "Failed to split file: Missing dependencies.")
    endif()

    # Splitting
    set(fileOffset 0)
    foreach(file IN ZIP_LISTS files lengths)
        do_split("${file_0}" ${file_1} "${fileOffset}")
        math(EXPR fileOffset "${fileOffset} + ${file_1}")
    endforeach()
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
    file_split(${SCRIPT_ARGN})
else()
    set(FILE_SPLIT_PATH "${CMAKE_CURRENT_LIST_FILE}")
endif()
