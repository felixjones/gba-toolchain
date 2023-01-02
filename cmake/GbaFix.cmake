if(VERIFY)
    string(LENGTH "${ROM_TITLE}" titleLength)
    if (${titleLength} GREATER 12)
        message(FATAL_ERROR "ROM_TITLE \"${ROM_TITLE}\" must not be more than 12 characters")
    endif()

    string(LENGTH "${ROM_ID}" idLength)
    if (${idLength} GREATER 4)
        message(FATAL_ERROR "ROM_ID \"${ROM_ID}\" must not be more than 4 characters")
    endif()

    string(LENGTH "${ROM_MAKER}" makerLength)
    if (${makerLength} GREATER 2)
        message(FATAL_ERROR "ROM_MAKER \"${ROM_MAKER}\" must not be more than 2 characters")
    endif()

    math(EXPR HEX_VERSION "${ROM_VERSION}" OUTPUT_FORMAT HEXADECIMAL)
    if(${HEX_VERSION} LESS 0 OR ${HEX_VERSION} GREATER 255)
        message(FATAL_ERROR "ROM_VERSION \"${ROM_VERSION}\" must be between 0 and 255")
    endif()
endif()

include("${CMAKE_CURRENT_LIST_DIR}/IHex.cmake")

function(gbafix input)
    macro(normalize_hex hex nibbleCount)
        if(NOT "${${hex}}" MATCHES "0x")
            math(EXPR ${hex} "${${hex}}" OUTPUT_FORMAT HEXADECIMAL)
        endif()
        string(REGEX REPLACE "^0x" "" ${hex} "${${hex}}")
        string(REPEAT "0" ${nibbleCount} padding)
        set(${hex} "${padding}${${hex}}")
        string(LENGTH "${${hex}}" padding)
        math(EXPR padding "${padding} - ${nibbleCount}")
        string(SUBSTRING "${${hex}}" ${padding} -1 ${hex})
    endmacro()

    macro(pad string length)
        string(LENGTH "${${string}}" stringLength)
        math(EXPR padLength "${length} - ${stringLength}")

        if(padLength GREATER 0)
            string(REPEAT "0" ${padLength} padding)
            set(${string} "${${string}}${padding}")
        endif()
    endmacro()

    set(oneValueArgs OUTPUT TITLE ID MAKER VERSION)
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "" ${ARGN})

    string(HEX "${ARGS_TITLE}" title)
    pad(title 24)
    string(HEX "${ARGS_ID}" id)
    pad(id 8)
    string(HEX "${ARGS_MAKER}" maker)
    pad(maker 4)
    normalize_hex(ARGS_VERSION 2)

    string(CONCAT header "${title}" "${id}" "${maker}" "96000000000000000000" "${ARGS_VERSION}")

    string(REGEX MATCHALL "([A-Fa-f0-9][A-Fa-f0-9])" headerBytes "${header}")
    set(complement 0)
    foreach(byte ${headerBytes})
        math(EXPR complement "${complement} + 0x${byte}")
    endforeach()
    math(EXPR complement "-(0x19 + ${complement})" OUTPUT_FORMAT HEXADECIMAL)
    normalize_hex(complement 2)

    file(READ "${input}" headerStart LIMIT 160 HEX) # Entry point + logo
    file(READ "${input}" binaryBody OFFSET 192 HEX) # Remaining ROM data

    # Convert to Intel HEX format
    ihex(outputHex RECORD_LENGTH 0xff "${headerStart}" "${header}" "${complement}" 0000 "${binaryBody}")

    string(RANDOM ihexFile)
    while(EXISTS "${ihexFile}.hex")
        string(RANDOM ihexFile)
    endwhile()

    # Write ihex file and objcopy into output binary
    file(WRITE "${ihexFile}.hex" "${outputHex}")
    execute_process(
        COMMAND "${CMAKE_OBJCOPY}" -I ihex "${ihexFile}.hex" -O binary "${ARGS_OUTPUT}"
    )
    file(REMOVE "${ihexFile}.hex")
endfunction()
