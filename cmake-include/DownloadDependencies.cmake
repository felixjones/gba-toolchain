include("${CMAKE_CURRENT_LIST_DIR}/KeyValue.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/DownloadExtract.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/DownloadCompile.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Detail.cmake")

function(gba_download_dependencies manifestUrl)
    cmake_minimum_required(VERSION 3.0)

    #====================
    # Detect host
    #====================

    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows OR CMAKE_HOST_SYSTEM_NAME MATCHES "MING.*" OR CMAKE_HOST_SYSTEM_NAME MATCHES "MSYS.*")
        set(KEY_ARM "arm-win32")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
        if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL aarch64)
            set(KEY_ARM "arm-aarch64-linux")
        elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL x86_64)
            set(KEY_ARM "arm-x86_64-linux")
        else()
            message(FATAL_ERROR "Failed to recognise host processor (${CMAKE_HOST_SYSTEM_PROCESSOR})")
        endif()
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

        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.txt" "gba-plusplus")
        set(URL_GBA_PLUSPLUS ${GBA_KEY_VALUE_OUT})

        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.txt" "maxmod")
        set(URL_MAXMOD ${GBA_KEY_VALUE_OUT})

        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.txt" "gbfs")
        set(URL_GBFS ${GBA_KEY_VALUE_OUT})

        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.txt" "agbabi")
        set(URL_AGBABI ${GBA_KEY_VALUE_OUT})
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

        # Replace URL_GBA_PLUSPLUS
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "gba-plusplus")
        set(TMP_URL_GBA_PLUSPLUS ${GBA_KEY_VALUE_OUT})
        if(NOT "${TMP_URL_GBA_PLUSPLUS}" STREQUAL "${URL_GBA_PLUSPLUS}")
            set(URL_GBA_PLUSPLUS "${TMP_URL_GBA_PLUSPLUS}")
        endif()

        # Replace URL_MAXMOD
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "maxmod")
        set(TMP_URL_MAXMOD ${GBA_KEY_VALUE_OUT})
        if(NOT "${TMP_URL_MAXMOD}" STREQUAL "${URL_MAXMOD}")
            set(URL_MAXMOD "${TMP_URL_MAXMOD}")
        endif()

        # Replace URL_GBFS
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "gbfs")
        set(TMP_URL_GBFS ${GBA_KEY_VALUE_OUT})
        if(NOT "${TMP_URL_GBFS}" STREQUAL "${URL_GBFS}")
            set(URL_GBFS "${TMP_URL_GBFS}")
        endif()

        # Replace URL_AGBABI
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "agbabi")
        set(TMP_URL_AGBABI ${GBA_KEY_VALUE_OUT})
        if(NOT "${TMP_URL_AGBABI}" STREQUAL "${URL_AGBABI}")
            set(URL_AGBABI "${TMP_URL_AGBABI}")
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

    get_filename_component(GBAFIX_NAME_WE "${URL_GBAFIX}" NAME_WE)
    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/tools/${GBAFIX_NAME_WE}")
        # Check URL_GBAFIX
        gba_github_get_commit("${URL_GBAFIX}")
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gbafix")
        if(NOT "${GBA_GITHUB_COMMIT_OUT}" STREQUAL "${GBA_KEY_VALUE_OUT}")
            if (NOT "${GBA_KEY_VALUE_OUT}" STREQUAL "")
                gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gbafix" "${GBA_GITHUB_COMMIT_OUT}")
            endif()
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

    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/lib/gba-plusplus")
        # Check URL_GBA_PLUSPLUS
        gba_github_get_commit("${URL_GBA_PLUSPLUS}")
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gba-plusplus")
        if(NOT "${GBA_GITHUB_COMMIT_OUT}" STREQUAL "${GBA_KEY_VALUE_OUT}")
            gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gba-plusplus" "${GBA_GITHUB_COMMIT_OUT}")
        else()
            # Already got it
            unset(URL_GBA_PLUSPLUS)
        endif()
    endif()

    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod")
        # Check URL_MAXMOD
        gba_github_get_commit("${URL_MAXMOD}")
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "maxmod")
        if(NOT "${GBA_GITHUB_COMMIT_OUT}" STREQUAL "${GBA_KEY_VALUE_OUT}")
            gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "maxmod" "${GBA_GITHUB_COMMIT_OUT}")
        else()
            # Already got it
            unset(URL_MAXMOD)
        endif()
    endif()

    get_filename_component(GBFS_NAME_WE "${URL_GBFS}" NAME_WE)
    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/tools/${GBFS_NAME_WE}")
        # Check URL_GBFS
        get_filename_component(GBFS_FILE "${URL_GBFS}" NAME_WE)
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gbfs")
        if(NOT "${GBFS_FILE}" STREQUAL "${GBA_KEY_VALUE_OUT}")
            gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gbfs" "${GBFS_FILE}")
        else()
            # Already got it
            unset(URL_GBFS)
        endif()
    endif()

    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/lib/agbabi")
        # Check URL_AGBABI
        gba_github_get_commit("${URL_AGBABI}")
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "agbabi")
        if(NOT "${GBA_GITHUB_COMMIT_OUT}" STREQUAL "${GBA_KEY_VALUE_OUT}")
            gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "agbabi" "${GBA_GITHUB_COMMIT_OUT}")
        else()
            # Already got it
            unset(URL_AGBABI)
        endif()
    endif()

    #====================
    # Download arm-gnu-toolchain
    #====================

    if(DEFINED URL_ARM)
        gba_download_extract("${URL_ARM}" "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain")

        get_filename_component(ARM_GNU_FILE "${URL_ARM}" NAME_WE)

        #====================
        # Move folders if needed
        #====================

        string(REGEX MATCH "(.*)(-win32|-x86_64-linux|-aarch64-linux|-mac)" _ "${ARM_GNU_FILE}")
        if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain/${CMAKE_MATCH_1}")
            file(RENAME "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain" "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain-tmp")
            file(RENAME "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain-tmp/${CMAKE_MATCH_1}" "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain")
            file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain-tmp")
        endif()

        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "arm-gnu" "${ARM_GNU_FILE}")
    endif()

    #====================
    # Download gbafix.c
    #====================

    if(DEFINED URL_GBAFIX)
        gba_download_compile("${URL_GBAFIX}" "${CMAKE_CURRENT_LIST_DIR}/tools")
        if (NOT "${GBA_COMPILE_C_OUT}" STREQUAL "")
            gba_github_get_commit("${URL_GBAFIX}")
            gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gbafix" "${GBA_GITHUB_COMMIT_OUT}")
        endif()
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

        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "tonc" "${GBA_GITHUB_COMMIT_OUT}")
    endif()

    #====================
    # Download gba-plusplus
    #====================

    if(DEFINED URL_GBA_PLUSPLUS)
        gba_download_extract("${URL_GBA_PLUSPLUS}" "${CMAKE_CURRENT_LIST_DIR}/lib/gba-plusplus")
        gba_github_get_commit("${URL_GBA_PLUSPLUS}")
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/lib/gba-plusplus/gba-plusplus-${GBA_GITHUB_COMMIT_OUT}/" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/gba-plusplus/")
        file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/lib/gba-plusplus/gba-plusplus-${GBA_GITHUB_COMMIT_OUT}/")

        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gba-plusplus" "${GBA_GITHUB_COMMIT_OUT}")
    endif()

    #====================
    # Download maxmod
    #====================

    if(DEFINED URL_MAXMOD)
        gba_download_extract("${URL_MAXMOD}" "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod")
        gba_github_get_commit("${URL_MAXMOD}")
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod/maxmod-${GBA_GITHUB_COMMIT_OUT}/" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod/")
        file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod/maxmod-${GBA_GITHUB_COMMIT_OUT}/")
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/cmake-include/MaxmodCMakeLists.cmake" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod")
        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod/MaxmodCMakeLists.cmake" "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod/CMakeLists.txt")

        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "maxmod" "${GBA_GITHUB_COMMIT_OUT}")
    endif()

    #====================
    # Download gbfs
    #====================

    if(DEFINED URL_GBFS)
        set(GBFS_COMPILE_SUCCESS ON)
        get_filename_component(GBFS_FILE "${URL_GBFS}" NAME_WE)
        gba_download_extract("${URL_GBFS}" "${CMAKE_CURRENT_LIST_DIR}/tools/${GBFS_FILE}")

        gba_compile_c("${CMAKE_CURRENT_LIST_DIR}/tools/${GBFS_FILE}/tools/gbfs.c" "${CMAKE_CURRENT_LIST_DIR}/tools")
        if ("${GBA_COMPILE_C_OUT}" STREQUAL "")
            set(GBFS_COMPILE_SUCCESS OFF)
        endif()

        gba_compile_c("${CMAKE_CURRENT_LIST_DIR}/tools/${GBFS_FILE}/tools/bin2s.c" "${CMAKE_CURRENT_LIST_DIR}/tools")
        if ("${GBA_COMPILE_C_OUT}" STREQUAL "")
            set(GBFS_COMPILE_SUCCESS OFF)
        endif()

        if (${GBFS_COMPILE_SUCCESS})
            # Copy gbfs library to lib/
            file(COPY "${CMAKE_CURRENT_LIST_DIR}/tools/${GBFS_FILE}/gbfs.h" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/gbfs/include/")
            file(COPY "${CMAKE_CURRENT_LIST_DIR}/tools/${GBFS_FILE}/libgbfs.c" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/gbfs/source/")
            file(COPY "${CMAKE_CURRENT_LIST_DIR}/cmake-include/GbfsCMakeLists.cmake" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/gbfs")
            file(RENAME "${CMAKE_CURRENT_LIST_DIR}/lib/gbfs/GbfsCMakeLists.cmake" "${CMAKE_CURRENT_LIST_DIR}/lib/gbfs/CMakeLists.txt")

            gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gbfs" "${GBFS_FILE}")
        endif()
    endif()

    #====================
    # Download agbabi
    #====================

    if(DEFINED URL_AGBABI)
        gba_download_extract("${URL_AGBABI}" "${CMAKE_CURRENT_LIST_DIR}/lib/agbabi")
        gba_github_get_commit("${URL_AGBABI}")
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/lib/agbabi/agbabi-${GBA_GITHUB_COMMIT_OUT}/" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/agbabi/")
        file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/lib/agbabi/agbabi-${GBA_GITHUB_COMMIT_OUT}/")

        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "agbabi" "${GBA_GITHUB_COMMIT_OUT}")
    endif()
endfunction()
