include("${CMAKE_CURRENT_LIST_DIR}/IHex.cmake")

function(binconcat align first)
    macro(pad str)
        if(${align} GREATER 1)
            string(LENGTH ${${str}} slen)
            math(EXPR slen "((${slen} / 2 + ${align} - 1) / ${align}) * ${align} - ${slen} / 2")
            string(REPEAT "00" ${slen} padding)
            string(APPEND ${str} ${padding})
        endif()
    endmacro()

    file(READ "${first}" temp HEX)
    string(APPEND binary ${temp})
    foreach(arg ${ARGN})
        pad(binary)
        file(READ "${arg}" temp HEX)
        string(APPEND binary ${temp})
    endforeach()

    ihex(outputHex RECORD_LENGTH 0xff "${binary}")

    string(RANDOM ihexFile)
    while(EXISTS "${ihexFile}.hex")
        string(RANDOM ihexFile)
    endwhile()

    # Write ihex file and objcopy into output binary
    file(WRITE "${ihexFile}.hex" "${outputHex}")
    execute_process(
        COMMAND "${CMAKE_OBJCOPY}" -I ihex "${ihexFile}.hex" -O binary "${first}"
    )
    file(REMOVE "${ihexFile}.hex")
endfunction()
