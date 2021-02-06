function(gba_compile_c source outPath)
    cmake_minimum_required(VERSION 3.0)

    get_filename_component(FILE_NAME_WE "${source}" NAME_WE)

    message(STATUS "Compiling ${source}")

    unset(CC CACHE)
    unset(GBA_COMPILE_C_OUT CACHE)

    file(MAKE_DIRECTORY "${outPath}/bin/")

    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows OR CMAKE_HOST_SYSTEM_NAME MATCHES "MING.*" OR CMAKE_HOST_SYSTEM_NAME MATCHES "MSYS.*")

        #====================
        # Compile Windows
        #====================

        # Visual Studio
        if(NOT CC)
            find_program(CC NAMES "cl.exe")
            if(CC)
                set(GBA_COMPILE_C_OUT "${outPath}/bin/${FILE_NAME_WE}.exe")
                execute_process(COMMAND "${CC}" "${source}" /link /out:"${GBA_COMPILE_C_OUT}")
            endif()
        endif()

        # GCC
        if(NOT CC)
            find_program(CC NAMES "gcc.exe")
            if(CC)
                set(GBA_COMPILE_C_OUT "${outPath}/bin/${FILE_NAME_WE}.exe")
                execute_process(COMMAND "${CC}" -w -o "${GBA_COMPILE_C_OUT}" "${source}")
            endif()
        endif()

        # Clang
        if(NOT CC)
            find_program(CC NAMES "clang.exe")
            if(CC)
                set(GBA_COMPILE_C_OUT "${outPath}/bin/${FILE_NAME_WE}.exe")
                execute_process(COMMAND "${CC}" -Wno-everything -o "${GBA_COMPILE_C_OUT}" "${source}")
            endif()
        endif()
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux OR CMAKE_HOST_SYSTEM_NAME STREQUAL Darwin)

        #====================
        # Compile *NIX
        #====================

        # GCC
        if(NOT CC)
            find_program(CC NAMES "gcc")
            if(CC)
                set(GBA_COMPILE_C_OUT "${outPath}/bin/${FILE_NAME_WE}")
                execute_process(COMMAND "${CC}" -w -o "${GBA_COMPILE_C_OUT}" "${source}")
            endif()
        endif()

        # Clang
        if(NOT CC)
            find_program(CC NAMES "clang")
            if(CC)
                set(GBA_COMPILE_C_OUT "${outPath}/bin/${FILE_NAME_WE}")
                execute_process(COMMAND "${CC}" -Wno-everything -o "${GBA_COMPILE_C_OUT}" "${source}")
            endif()
        endif()
    else()
        message(FATAL_ERROR "Failed to recognise host operating system (${CMAKE_HOST_SYSTEM_NAME})")
    endif()

    if(NOT CC)
        message(WARNING "Could not find a host compiler for \"${source}\"")
    endif()

    set(GBA_COMPILE_C_OUT "${GBA_COMPILE_C_OUT}" PARENT_SCOPE)
endfunction()

function(gba_download_compile url path)
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

    #====================
    # Compile file
    #====================

    gba_compile_c("${path}/${FILE_NAME_WE}/${FILE_NAME}" "${path}")
    set(GBA_COMPILE_C_OUT "${GBA_COMPILE_C_OUT}" PARENT_SCOPE)
endfunction()
