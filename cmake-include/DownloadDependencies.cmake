include("${CMAKE_CURRENT_LIST_DIR}/KeyValue.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/DownloadExtract.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/DownloadCompile.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Detail.cmake")

function(gba_download_dependencies manifestUrl)
    cmake_minimum_required(VERSION 3.1)

    #====================
    # Detect host
    #====================

    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
        set(KEY_ARM "arm-win32")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
        set(KEY_ARM "arm-x86_64-linux")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Darwin)
        set(KEY_ARM "arm-mac")
    else()
        message(FATAL_ERROR "Failed to recognise host operating system (${CMAKE_HOST_SYSTEM_NAME})")
    endif()

    #====================
    # Parse URLs
    #====================

    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/urls.txt")
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.txt" "${KEY_ARM}")
        set(URL_ARM ${GBA_KEY_VALUE_OUT})

        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.txt" "gbafix")
        set(URL_GBAFIX ${GBA_KEY_VALUE_OUT})

        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.txt" "tonc")
        set(URL_TONC ${GBA_KEY_VALUE_OUT})
    endif()

    #====================
    # Update URLs
    #====================

    file(DOWNLOAD "${manifestUrl}" "${CMAKE_CURRENT_LIST_DIR}/urls.tmp")
    file(READ "${CMAKE_CURRENT_LIST_DIR}/urls.tmp" URLS)

    if(NOT "${URLS}" STREQUAL "")
        # Replace URL_ARM
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "${KEY_ARM}")
        set(TMP_URL_ARM ${GBA_KEY_VALUE_OUT})
        if(NOT "${TMP_URL_ARM}" STREQUAL "${URL_ARM}")
            set(URL_ARM "${TMP_URL_ARM}")
        endif()

        # Replace URL_GBAFIX
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "gbafix")
        set(TMP_URL_GBAFIX ${GBA_KEY_VALUE_OUT})
        if(NOT "${TMP_URL_GBAFIX}" STREQUAL "${URL_GBAFIX}")
            set(URL_GBAFIX "${TMP_URL_GBAFIX}")
        endif()

        # Replace URL_TONC
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "tonc")
        set(TMP_URL_TONC ${GBA_KEY_VALUE_OUT})
        if(NOT "${TMP_URL_TONC}" STREQUAL "${URL_TONC}")
            set(URL_TONC "${TMP_URL_TONC}")
        endif()

        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "${CMAKE_CURRENT_LIST_DIR}/urls.txt")
    endif()
    file(REMOVE "${CMAKE_CURRENT_LIST_DIR}/urls.tmp")

    #====================
    # Check dependency manifest
    #====================

    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain/arm-none-eabi")
        # Check URL_ARM
        get_filename_component(ARM_GNU_FILE "${URL_ARM}" NAME_WE)
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "arm-gnu")
        if(NOT "${ARM_GNU_FILE}" STREQUAL "${GBA_KEY_VALUE_OUT}")
            gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "arm-gnu" "${ARM_GNU_FILE}")
        else()
            # Already got it
            unset(URL_ARM)
        endif()
    endif()

    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/tools")
        # Check URL_GBAFIX
        gba_github_get_commit("${URL_GBAFIX}")
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gbafix")
        if(NOT "${GBA_GITHUB_COMMIT_OUT}" STREQUAL "${GBA_KEY_VALUE_OUT}")
            gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gbafix" "${GBA_GITHUB_COMMIT_OUT}")
        else()
            # Already got it
            unset(URL_GBAFIX)
        endif()
    endif()

    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/lib/tonc")
        # Check URL_TONC
        gba_github_get_commit("${URL_TONC}")
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "tonc")
        if(NOT "${GBA_GITHUB_COMMIT_OUT}" STREQUAL "${GBA_KEY_VALUE_OUT}")
            gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "tonc" "${GBA_GITHUB_COMMIT_OUT}")
        else()
            # Already got it
            unset(URL_TONC)
        endif()
    endif()

    #====================
    # Download arm-gnu-toolchain
    #====================

    if(DEFINED URL_ARM)
        gba_download_extract("${URL_ARM}" "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain")
    endif()

    #====================
    # Download gbafix.c
    #====================

    if(DEFINED URL_GBAFIX)
        gba_download_compile("${URL_GBAFIX}" "${CMAKE_CURRENT_LIST_DIR}/tools")
    endif()

    #====================
    # Download libtonc
    #====================

    if(DEFINED URL_TONC)
        gba_download_extract("${URL_TONC}" "${CMAKE_CURRENT_LIST_DIR}/lib/tonc")
        gba_github_get_commit("${URL_TONC}")
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/lib/tonc/libtonc-${GBA_GITHUB_COMMIT_OUT}/" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/tonc/")
        file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/lib/tonc/libtonc-${GBA_GITHUB_COMMIT_OUT}/")
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/cmake-include/ToncCMakeLists.cmake" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/tonc")
        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/lib/tonc/ToncCMakeLists.cmake" "${CMAKE_CURRENT_LIST_DIR}/lib/tonc/CMakeLists.txt")
    endif()
endfunction()
