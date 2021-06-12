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
        string(REGEX MATCH "[a-zA-Z0-9.:\\/-]+\\/(.*)\\." _ "${url}")
        if(NOT "${CMAKE_MATCH_1}" STREQUAL "")
            set(GITHUB_COMMIT_OUT "${CMAKE_MATCH_1}")
        endif()
    endif()

    set(GBA_GITHUB_COMMIT_OUT "${GITHUB_COMMIT_OUT}" PARENT_SCOPE)
endfunction()

function(gba_list_directories path)
    cmake_minimum_required(VERSION 3.0)

    set(dirlist "")

    file(GLOB children RELATIVE ${path} ${path}/*)
    foreach(child ${children})
        if(IS_DIRECTORY ${path}/${child})
            list(APPEND dirlist ${child})
        endif()
    endforeach()

    set(GBA_LIST_DIRECTORIES_OUT ${dirlist} PARENT_SCOPE)
endfunction()

function(gba_move_inner_path path)
    cmake_minimum_required(VERSION 3.0)

    set(dirlist "")

    file(GLOB children RELATIVE ${path} ${path}/*)
    foreach(child ${children})
        if(IS_DIRECTORY ${path}/${child})
            list(APPEND dirlist ${path}/${child})
        endif()
    endforeach()

    list(LENGTH dirlist dirlength)
    if(${dirlength} GREATER 1)
        message(FATAL_ERROR "Too many directories in ${path}")
    elseif(${dirlength} EQUAL 1)
        list(GET dirlist 0 innerpath)
        file(RENAME ${innerpath} "${path}-tmp")
        file(REMOVE_RECURSE "${path}")
        file(RENAME "${path}-tmp" ${path})
    endif()
endfunction()
