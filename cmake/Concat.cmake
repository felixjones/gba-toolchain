include("${CMAKE_CURRENT_LIST_DIR}/IHex.cmake")

function(binconcat first)
    # TODO: Alignment

    file(READ "${first}" temp HEX)
    list(APPEND binary ${temp})
    foreach(arg ${ARGN})
        file(READ "${arg}" temp HEX)
        list(APPEND binary ${temp})
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
