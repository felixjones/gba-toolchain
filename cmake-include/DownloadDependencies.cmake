include("${CMAKE_CURRENT_LIST_DIR}/KeyValue.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/DownloadExtract.cmake")
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
    # Lock guard acquire
    #====================

    if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.2.0")
        if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/cmake.lock")
            message(STATUS "Waiting for CMake instances to complete")
        endif()
        file(LOCK "${CMAKE_CURRENT_LIST_DIR}/cmake.lock" GUARD FUNCTION)
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

        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.txt" "posprintf")
        set(URL_POSPRINTF ${GBA_KEY_VALUE_OUT})

        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.txt" "nedclib")
        set(URL_NEDCLIB ${GBA_KEY_VALUE_OUT})

        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.txt" "fatfs")
        set(URL_FATFS ${GBA_KEY_VALUE_OUT})
    endif()

    #====================
    # Update URLs
    #====================

    if (UPDATE_URLS_TXT)
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

            # Replace URL_POSPRINTF
            gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "posprintf")
            set(TMP_URL_POSPRINTF ${GBA_KEY_VALUE_OUT})
            if(NOT "${TMP_URL_POSPRINTF}" STREQUAL "${URL_POSPRINTF}")
                set(URL_POSPRINTF "${TMP_URL_POSPRINTF}")
            endif()

            # Replace URL_NEDCLIB
            gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "nedclib")
            set(TMP_URL_NEDCLIB ${GBA_KEY_VALUE_OUT})
            if(NOT "${TMP_URL_NEDCLIB}" STREQUAL "${URL_NEDCLIB}")
                set(URL_NEDCLIB "${TMP_URL_NEDCLIB}")
            endif()

            # Replace URL_FATFAT
            gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "fatfs")
            set(TMP_URL_FATFAT ${GBA_KEY_VALUE_OUT})
            if(NOT "${TMP_URL_FATFAT}" STREQUAL "${URL_FATFAT}")
                set(URL_FATFAT "${TMP_URL_FATFAT}")
            endif()

            file(RENAME "${CMAKE_CURRENT_LIST_DIR}/urls.tmp" "${CMAKE_CURRENT_LIST_DIR}/urls.txt")
        endif()
        file(REMOVE "${CMAKE_CURRENT_LIST_DIR}/urls.tmp")
    endif()

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

        if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/lib/gba-plusplus/.git/")
            message(STATUS "gba-plusplus developer mode")
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

        if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/lib/agbabi/.git/")
            message(STATUS "agbabi developer mode")
            unset(URL_AGBABI)
        endif()
    endif()

    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf")
        # Check URL_POSPRINTF
        get_filename_component(POSPRINTF_FILE "${URL_POSPRINTF}" NAME_WE)
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "posprintf")
        if(NOT "${POSPRINTF_FILE}" STREQUAL "${GBA_KEY_VALUE_OUT}")
            gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "posprintf" "${POSPRINTF_FILE}")
        else()
            # Already got it
            unset(URL_POSPRINTF)
        endif()
    endif()

    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/tools/nedclib")
        # Check URL_NEDCLIB
        gba_github_get_commit("${URL_NEDCLIB}")
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "nedclib")
        if(NOT "${GBA_GITHUB_COMMIT_OUT}" STREQUAL "${GBA_KEY_VALUE_OUT}")
            if (NOT "${GBA_KEY_VALUE_OUT}" STREQUAL "")
                gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "nedclib" "${GBA_GITHUB_COMMIT_OUT}")
            endif()
        else()
            # Already got it
            unset(URL_NEDCLIB)
        endif()
    endif()

    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/lib/flashcart/fatfs")
        # Check URL_FATFS
        get_filename_component(FATFS_FILE "${URL_FATFS}" NAME_WE)
        gba_key_value_get("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "fatfs")
        if(NOT "${FATFS_FILE}" STREQUAL "${GBA_KEY_VALUE_OUT}")
            gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "fatfs" "${FATFS_FILE}")
        else()
            # Already got it
            unset(URL_FATFS)
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
        gba_download("${URL_GBAFIX}" "${CMAKE_CURRENT_LIST_DIR}/tools")

        file(COPY "${CMAKE_CURRENT_LIST_DIR}/cmake-include/GbaFixCMakeLists.cmake" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/tools/gbafix")
        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/tools/gbafix/GbaFixCMakeLists.cmake" "${CMAKE_CURRENT_LIST_DIR}/tools/gbafix/CMakeLists.txt")

        gba_github_get_commit("${URL_GBAFIX}")
        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gbafix" "${GBA_GITHUB_COMMIT_OUT}")
    endif()

    #====================
    # Download libtonc
    #====================

    if(DEFINED URL_TONC)
        gba_download_extract("${URL_TONC}" "${CMAKE_CURRENT_LIST_DIR}/lib/tonc")
        gba_move_inner_path("${CMAKE_CURRENT_LIST_DIR}/lib/tonc")

        file(COPY "${CMAKE_CURRENT_LIST_DIR}/cmake-include/ToncCMakeLists.cmake" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/tonc")
        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/lib/tonc/ToncCMakeLists.cmake" "${CMAKE_CURRENT_LIST_DIR}/lib/tonc/CMakeLists.txt")

        gba_github_get_commit("${URL_TONC}")
        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "tonc" "${GBA_GITHUB_COMMIT_OUT}")
    endif()

    #====================
    # Download gba-plusplus
    #====================

    if(DEFINED URL_GBA_PLUSPLUS)
        gba_download_extract("${URL_GBA_PLUSPLUS}" "${CMAKE_CURRENT_LIST_DIR}/lib/gba-plusplus")
        gba_move_inner_path("${CMAKE_CURRENT_LIST_DIR}/lib/gba-plusplus")

        gba_github_get_commit("${URL_GBA_PLUSPLUS}")
        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gba-plusplus" "${GBA_GITHUB_COMMIT_OUT}")
    endif()

    #====================
    # Download maxmod
    #====================

    if(DEFINED URL_MAXMOD)
        gba_download_extract("${URL_MAXMOD}" "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod")
        gba_move_inner_path("${CMAKE_CURRENT_LIST_DIR}/lib/maxmod")

        file(COPY "${CMAKE_CURRENT_LIST_DIR}/cmake-include/MaxmodCMakeLists.cmake" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod")
        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod/MaxmodCMakeLists.cmake" "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod/CMakeLists.txt")

        gba_github_get_commit("${URL_MAXMOD}")
        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "maxmod" "${GBA_GITHUB_COMMIT_OUT}")
    endif()

    #====================
    # Download gbfs
    #====================

    if(DEFINED URL_GBFS)
        get_filename_component(GBFS_FILE "${URL_GBFS}" NAME_WE)
        gba_download_extract("${URL_GBFS}" "${CMAKE_CURRENT_LIST_DIR}/tools/${GBFS_FILE}")

        file(COPY "${CMAKE_CURRENT_LIST_DIR}/cmake-include/GbfsCMakeLists.cmake" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/tools/gbfs")
        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/tools/gbfs/GbfsCMakeLists.cmake" "${CMAKE_CURRENT_LIST_DIR}/tools/gbfs/CMakeLists.txt")

        # Copy gbfs library to lib/
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/tools/${GBFS_FILE}/gbfs.h" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/gbfs/include/")
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/tools/${GBFS_FILE}/libgbfs.c" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/gbfs/source/")
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/cmake-include/GbfsCMakeLists.cmake" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/gbfs")
        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/lib/gbfs/GbfsCMakeLists.cmake" "${CMAKE_CURRENT_LIST_DIR}/lib/gbfs/CMakeLists.txt")

        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "gbfs" "${GBFS_FILE}")
    endif()

    #====================
    # Download agbabi
    #====================

    if(DEFINED URL_AGBABI)
        gba_download_extract("${URL_AGBABI}" "${CMAKE_CURRENT_LIST_DIR}/lib/agbabi")
        gba_move_inner_path("${CMAKE_CURRENT_LIST_DIR}/lib/agbabi")

        gba_github_get_commit("${URL_AGBABI}")
        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "agbabi" "${GBA_GITHUB_COMMIT_OUT}")
    endif()

    #====================
    # Download posprintf
    #====================

    if(DEFINED URL_POSPRINTF)
        get_filename_component(POSPRINTF_FILE "${URL_POSPRINTF}" NAME_WE)
        gba_download_extract("${URL_POSPRINTF}" "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf")

        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf" "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf_tmp")
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf_tmp/posprintf/" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf")
        file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf_tmp/")

        # Move header into include dir
        file(COPY "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf/posprintf.h" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf/include/")

        file(COPY "${CMAKE_CURRENT_LIST_DIR}/cmake-include/PosprintfCMakeLists.cmake" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf")
        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf/PosprintfCMakeLists.cmake" "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf/CMakeLists.txt")

        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "posprintf" "${POSPRINTF_FILE}")
    endif()

    #====================
    # Download nedclib
    #====================

    if(DEFINED URL_NEDCLIB)
        gba_download_extract("${URL_NEDCLIB}" "${CMAKE_CURRENT_LIST_DIR}/tools/nedclib")
        gba_move_inner_path("${CMAKE_CURRENT_LIST_DIR}/tools/nedclib")

        file(COPY "${CMAKE_CURRENT_LIST_DIR}/cmake-include/NedclibCMakeLists.cmake" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/tools/nedclib")
        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/tools/nedclib/NedclibCMakeLists.cmake" "${CMAKE_CURRENT_LIST_DIR}/tools/nedclib/CMakeLists.txt")

        gba_github_get_commit("${URL_NEDCLIB}")
        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "nedclib" "${GBA_GITHUB_COMMIT_OUT}")
    endif()

    #====================
    # Download FatFs
    #====================

    if(DEFINED URL_FATFS)
        get_filename_component(FATFS_FILE "${URL_FATFS}" NAME_WE)
        gba_download_extract("${URL_FATFS}" "${CMAKE_CURRENT_LIST_DIR}/lib/flashcart/fatfs")

        file(COPY "${CMAKE_CURRENT_LIST_DIR}/lib/flashcart/flashcart_ffconf.h" DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/flashcart/fatfs/source")
        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/lib/flashcart/fatfs/source/ffconf.h" "${CMAKE_CURRENT_LIST_DIR}/lib/flashcart/fatfs/source/ffconf.old.h")
        file(RENAME "${CMAKE_CURRENT_LIST_DIR}/lib/flashcart/fatfs/source/flashcart_ffconf.h" "${CMAKE_CURRENT_LIST_DIR}/lib/flashcart/fatfs/source/ffconf.h")

        gba_key_value_set("${CMAKE_CURRENT_LIST_DIR}/dependencies.txt" "fatfs" "${FATFS_FILE}")
    endif()

    #====================
    # Lock guard release
    #====================

    if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.2.0")
        file(LOCK "${CMAKE_CURRENT_LIST_DIR}/cmake.lock" RELEASE)
        file(REMOVE "${CMAKE_CURRENT_LIST_DIR}/cmake.lock")
    endif()

endfunction()
