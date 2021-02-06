function(gba_key_value_get filePath searchKey)
    cmake_minimum_required(VERSION 3.0)

    if(EXISTS "${filePath}")
        file(READ "${filePath}" FILE_STRING)
        string(REGEX MATCH "${searchKey}[ \t]*=[ \t]*([^\r\n]*)" _ ${FILE_STRING})

        set(GBA_KEY_VALUE_OUT "${CMAKE_MATCH_1}" PARENT_SCOPE)
    else()
        unset(GBA_KEY_VALUE_OUT PARENT_SCOPE)
    endif()
endfunction()

function(gba_key_value_set filePath key value)
    cmake_minimum_required(VERSION 3.0)

    if(NOT EXISTS "${filePath}")
        file(WRITE "${filePath}" "${key}=${value}")
    else()
        file(READ "${filePath}" FILE_STRING)

        string(REGEX MATCH "${searchKey}[ \t]*=[ \t]*([^\r\n]*)" _ ${FILE_STRING})

        if(NOT "${CMAKE_MATCH_1}" STREQUAL "")
            string(REGEX REPLACE "(${key}[ \t]*=[ \t]*[^\r\n]*[\r\n]*)" "" FILE_STRING "${FILE_STRING}")
        endif()
        file(WRITE "${filePath}" "${key}=${value}\r\n${FILE_STRING}")
    endif()
endfunction()
