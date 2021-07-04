function(gba_download url path)
    cmake_minimum_required(VERSION 3.0)

    get_filename_component(FILE_NAME "${url}" NAME)
    get_filename_component(FILE_NAME_WE "${url}" NAME_WE)

    #====================
    # Check path is empty
    #====================

    file(REMOVE_RECURSE "${path}/${FILE_NAME_WE}")

    #====================
    # Download file
    #====================

    message(STATUS "Downloading ${url}")
    file(DOWNLOAD "${url}" "${path}/${FILE_NAME_WE}/${FILE_NAME}" SHOW_PROGRESS)
endfunction()

function(gba_download_extract url path)
    cmake_minimum_required(VERSION 3.0)

    get_filename_component(FILE_NAME "${url}" NAME)

    #====================
    # Check path is empty
    #====================

    file(REMOVE_RECURSE "${path}")

    #====================
    # Download file
    #====================

    message(STATUS "Downloading ${url}")
    file(DOWNLOAD "${url}" "${path}/${FILE_NAME}" SHOW_PROGRESS)

    #====================
    # Extract file
    #====================

    message(STATUS "Extracting ${FILE_NAME}")

    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
        execute_process(
            COMMAND powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('${path}/${FILE_NAME}', '${path}/'); }"
        )
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux OR CMAKE_HOST_SYSTEM_NAME STREQUAL Darwin OR CMAKE_HOST_SYSTEM_NAME MATCHES "MING.*" OR CMAKE_HOST_SYSTEM_NAME MATCHES "MSYS.*")
        get_filename_component(FILE_EXT "${path}/${FILE_NAME}" EXT)
        if(${FILE_EXT} MATCHES ".zip$")
            execute_process(
                COMMAND unzip "${path}/${FILE_NAME}" -d "${path}/"
            )
        elseif(${FILE_EXT} STREQUAL ".tar.bz2")
            execute_process(
                COMMAND tar -xvf "${path}/${FILE_NAME}" -C "${path}/" --strip-components=1
            )
        else()
            message(FATAL_ERROR "Unsupported extension (${FILE_EXT})")
        endif()
    else()
        message(FATAL_ERROR "Failed to recognise host operating system (${CMAKE_HOST_SYSTEM_NAME})")
    endif()

    #====================
    # Cleanup
    #====================

    file(REMOVE "${path}/${FILE_NAME}")
endfunction()
