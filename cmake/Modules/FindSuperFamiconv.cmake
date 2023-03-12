include(FetchContent)

find_program(CMAKE_SUPERFAMICONV_PROGRAM superfamiconv PATHS "${CMAKE_SYSTEM_LIBRARY_PATH}/superfamiconv" "${SUPERFAMICONV_DIR}" PATH_SUFFIXES bin)

if(NOT CMAKE_SUPERFAMICONV_PROGRAM)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/superfamiconv")

    FetchContent_Declare(superfamiconv_proj DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        SOURCE_DIR "${SOURCE_DIR}/source"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/Optiroc/SuperFamiconv.git"
        GIT_TAG "master"
    )

    FetchContent_MakeAvailable(superfamiconv_proj)

    # Configure
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -S . -B "${SOURCE_DIR}/build"
        WORKING_DIRECTORY "${SOURCE_DIR}/source"
        RESULT_VARIABLE cmakeResult
    )

    if(cmakeResult EQUAL "1")
        message(WARNING "Failed to configure superfamiconv")
    else()
        # Build
        execute_process(
            COMMAND "${CMAKE_COMMAND}" --build . --config Release
            WORKING_DIRECTORY "${SOURCE_DIR}/build"
            RESULT_VARIABLE cmakeResult
        )

        if(cmakeResult EQUAL "1")
            message(WARNING "Failed to build superfamiconv")
        else()
            # Install
            execute_process(
                COMMAND ${CMAKE_COMMAND} --install . --prefix "${SOURCE_DIR}" --config Release
                WORKING_DIRECTORY "${SOURCE_DIR}/build"
                RESULT_VARIABLE cmakeResult
            )

            if(cmakeResult EQUAL "1")
                message(WARNING "Failed to install superfamiconv")
            else()
                find_program(CMAKE_SUPERFAMICONV_PROGRAM superfamiconv PATHS "${SOURCE_DIR}/bin")
            endif()
        endif()
    endif()
endif()

if(NOT CMAKE_SUPERFAMICONV_PROGRAM)
    message(WARNING "superfamiconv not found: Please set `-DCMAKE_SUPERFAMICONV_PROGRAM:FILEPATH=<path/to/bin/superfamiconv>`")
endif()
