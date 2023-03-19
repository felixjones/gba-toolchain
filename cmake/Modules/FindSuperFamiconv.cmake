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

set(SUPERFAMICONV_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/../SuperFamiconv.cmake")

function(add_superfamiconv_graphics target)
    set(oneValueArgs
        EXCLUDE_FROM_ALL
        PALETTE
        TILES
        MAP
    )

    cmake_parse_arguments(ARGS "${oneValueArgs}" "" "" ${ARGN})

    if(NOT ARGS_PALETTE OR NOT ARGS_TILES OR NOT ARGS_MAP)
        message(FATAL_ERROR "add_superfamiconv_graphics requires PALETTE, TILES, or MAP")
    endif()

    set(SOURCES $<TARGET_PROPERTY:${target},SOURCES>)

    if(NOT ARGS_EXCLUDE_FROM_ALL)
        set(INCLUDE_WITH_ALL ALL)
    endif()

    # TODO: Find a bug reference for the below hack
    string(REGEX REPLACE "([][+.*()^])" "\\\\\\1" SOURCES_BUG_FIX "${CMAKE_BINARY_DIR}/CMakeFiles/${target}")

    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/_stamp")
    set(STAMP "${CMAKE_BINARY_DIR}/_stamp/${target}.stamp")

    set(commands)
    if(ARGS_PALETTE)
        list(APPEND commands COMMAND "${CMAKE_COMMAND}" -DPALETTE=ON
            "-DPROGRAM=${CMAKE_SUPERFAMICONV_PROGRAM}"
            "-DPARAMS=$<TARGET_PROPERTY:${target},ARGS_PALETTE>"
            "-DPREFIX=$<TARGET_GENEX_EVAL:${target},$<TARGET_PROPERTY:${target},PREFIX_PALETTE>>"
            "-DSUFFIX=$<TARGET_PROPERTY:${target},SUFFIX_PALETTE>"
            "-DINPUTS=$<FILTER:${SOURCES},EXCLUDE,${SOURCES_BUG_FIX}|[.]rule>"
            -P ${SUPERFAMICONV_SCRIPT}
        )
    endif()
    if(ARGS_TILES)
        list(APPEND commands COMMAND "${CMAKE_COMMAND}" -DTILES=ON
            "-DPROGRAM=${CMAKE_SUPERFAMICONV_PROGRAM}"
            "-DPARAMS=$<TARGET_PROPERTY:${target},ARGS_TILES>"
            "-DPREFIX=$<TARGET_GENEX_EVAL:${target},$<TARGET_PROPERTY:${target},PREFIX_TILES>>"
            "-DSUFFIX=$<TARGET_PROPERTY:${target},SUFFIX_TILES>"
            "-DINPUTS=$<FILTER:${SOURCES},EXCLUDE,${SOURCES_BUG_FIX}|[.]rule>"
            "-DPREFIX_PALETTE=$<TARGET_GENEX_EVAL:${target},$<TARGET_PROPERTY:${target},PREFIX_PALETTE>>"
            "-DSUFFIX_PALETTE=$<TARGET_PROPERTY:${target},SUFFIX_PALETTE>"
            -P ${SUPERFAMICONV_SCRIPT}
        )
    endif()
    if(ARGS_MAP)
        list(APPEND commands COMMAND "${CMAKE_COMMAND}" -DMAP=ON
            "-DPROGRAM=${CMAKE_SUPERFAMICONV_PROGRAM}"
            "-DPARAMS=$<TARGET_PROPERTY:${target},ARGS_MAP>"
            "-DPREFIX=$<TARGET_GENEX_EVAL:${target},$<TARGET_PROPERTY:${target},PREFIX_MAP>>"
            "-DSUFFIX=$<TARGET_PROPERTY:${target},SUFFIX_MAP>"
            "-DINPUTS=$<FILTER:${SOURCES},EXCLUDE,${SOURCES_BUG_FIX}|[.]rule>"
            "-DPREFIX_PALETTE=$<TARGET_GENEX_EVAL:${target},$<TARGET_PROPERTY:${target},PREFIX_PALETTE>>"
            "-DSUFFIX_PALETTE=$<TARGET_PROPERTY:${target},SUFFIX_PALETTE>"
            "-DPREFIX_TILES=$<TARGET_GENEX_EVAL:${target},$<TARGET_PROPERTY:${target},PREFIX_TILES>>"
            "-DSUFFIX_TILES=$<TARGET_PROPERTY:${target},SUFFIX_TILES>"
            -P ${SUPERFAMICONV_SCRIPT}
        )
    endif()

    add_custom_command(OUTPUT ${STAMP}
        ${commands}
        COMMAND "${CMAKE_COMMAND}" -E touch ${STAMP}
        DEPENDS $<FILTER:${SOURCES},EXCLUDE,${SOURCES_BUG_FIX}|[.]rule>
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        VERBATIM
        COMMENT "Generating ${target}"
    )

    add_custom_target(${target} ${INCLUDE_WITH_ALL} DEPENDS ${STAMP})

    set_target_properties(${target} PROPERTIES
        OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        OUTPUT_NAME "${target}"
        PREFIX_PALETTE "$<TARGET_PROPERTY:${target},OUTPUT_DIRECTORY>/"
        PREFIX_TILES "$<TARGET_PROPERTY:${target},OUTPUT_DIRECTORY>/"
        PREFIX_MAP "$<TARGET_PROPERTY:${target},OUTPUT_DIRECTORY>/"
        SUFFIX_PALETTE ".palette"
        SUFFIX_TILES ".tiles"
        SUFFIX_MAP ".map"
        ARGS_PALETTE ""
        ARGS_TILES ""
        ARGS_MAP ""
    )

    if(ARGS_UNPARSED_ARGUMENTS)
        set_target_properties(${target} PROPERTIES
            SOURCES "${ARGS_UNPARSED_ARGUMENTS}"
        )
    endif()
endfunction()
