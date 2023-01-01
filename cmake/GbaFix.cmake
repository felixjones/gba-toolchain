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

macro(normalize_hex value nibbles)
    if(NOT "${${value}}" MATCHES "0x")
        math(EXPR ${value} "${${value}}" OUTPUT_FORMAT HEXADECIMAL)
    endif()
    string(REGEX REPLACE "^0x" "" ${value} "${${value}}")
    string(REPEAT "0" ${nibbles} padding)
    set(${value} "${padding}${${value}}")
    string(LENGTH "${${value}}" padding)
    math(EXPR padding "${padding} - ${nibbles}")
    string(SUBSTRING "${${value}}" ${padding} -1 ${value})
endmacro()

function(bwrite output hexString)
    list(JOIN hexString "" hexString)
    string(LENGTH "${hexString}" length)

    macro(checksum sum hexString)
        string(REGEX MATCHALL "([A-Fa-f0-9][A-Fa-f0-9])" bytes ${${hexString}})

        set(${sum} 0)
        foreach(byte ${bytes})
            math(EXPR ${sum} "${${sum}} + 0x${byte}")
        endforeach()
        math(EXPR ${sum} "1 + ~${${sum}}" OUTPUT_FORMAT HEXADECIMAL)
        normalize_hex(${sum} 2)
    endmacro()

    set(addrMajor 0)
    set(addrMinor 0)
    set(outputHex "")

    set(idx 0)
    while(idx LESS ${length})
        if(addrMinor EQUAL 0)
            normalize_hex(addrMajor 4)
            set(extendedAddress "02000004${addrMajor}")
            checksum(crc extendedAddress)
            string(APPEND outputHex ":" "${extendedAddress}" "${crc}" "\n")
            math(EXPR addrMajor "0x${addrMajor} + 1")
        endif()

        string(SUBSTRING "${hexString}" ${idx} 32 dataString) # 32 nibbles of hex data (16 bytes)
        string(LENGTH "${dataString}" dataLength)
        math(EXPR dataLength "${dataLength} / 2")
        normalize_hex(dataLength 2)
        normalize_hex(addrMinor 4)

        set(dataString "${dataLength}${addrMinor}00${dataString}")
        checksum(crc dataString)
        string(APPEND outputHex ":" ${dataString} ${crc} "\n")

        math(EXPR addrMinor "(0x${addrMinor} + 16) % 0x10000")
        math(EXPR idx "${idx} + 32")
    endwhile()
    string(APPEND outputHex ":00000001ff\n")

    string(REGEX REPLACE "[.].+$" ".hex" hexPath "${output}")
    file(WRITE "${hexPath}" "${outputHex}")

    execute_process(
        COMMAND "${CMAKE_OBJCOPY}" -I ihex "${hexPath}" -O binary "${output}"
    )

    file(REMOVE "${hexPath}")
endfunction()

function(gbafix input)
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

    bwrite("${ARGS_OUTPUT}" "${headerStart}${header}${complement}0000${binaryBody}")
endfunction()
