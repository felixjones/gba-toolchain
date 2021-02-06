function(gba_github_get_commit url)
    cmake_minimum_required(VERSION 3.0)

    unset(GITHUB_COMMIT_OUT)

    if("${GITHUB_COMMIT_OUT}" STREQUAL "")
        string(REGEX MATCH "raw\\.githubusercontent\\.com+\\/+[^\\/]+\\/+[^\\/]+\\/+([a-z0-9]*)[^\\s]+" _ "${url}")
        if(NOT "${CMAKE_MATCH_1}" STREQUAL "")
            set(GITHUB_COMMIT_OUT "${CMAKE_MATCH_1}")
        endif()
    endif()

    if("${GITHUB_COMMIT_OUT}" STREQUAL "")
        string(REGEX MATCH "github\\.com+\\/+[^\\/]+\\/+[^\\/]+\\/+archive+\\/+([a-z0-9]*)[^\\s]+" _ "${url}")
        if(NOT "${CMAKE_MATCH_1}" STREQUAL "")
            set(GITHUB_COMMIT_OUT "${CMAKE_MATCH_1}")
        endif()
    endif()

    set(GBA_GITHUB_COMMIT_OUT "${GITHUB_COMMIT_OUT}" PARENT_SCOPE)
endfunction()
