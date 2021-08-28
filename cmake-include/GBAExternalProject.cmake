function(gba_external_project_add name)
    cmake_minimum_required(VERSION 3.0)

    set(options)
    set(keywords
        #
        # Directory options
        #
        SOURCE_DIR
        BINARY_DIR
    )
    set(multi
        #
        # Install step options
        #
        INSTALL_COMMAND
        #
        # Configure step options
        #
        CMAKE_COMMAND
        CMAKE_ARGS
        CMAKE_CACHE_ARGS
        CMAKE_CACHE_DEFAULT_ARGS
    )
    cmake_parse_arguments(gba_external_project_add "${options}" "${keywords}" "${multi}" "${ARGN}")

    if (NOT DEFINED gba_external_project_add_SOURCE_DIR)
        message(FATAL_ERROR "gba_external_project_add \"${name}\" requires SOURCE_DIR")
    endif()
    if (NOT DEFINED gba_external_project_add_BINARY_DIR)
        message(FATAL_ERROR "gba_external_project_add \"${name}\" requires BINARY_DIR")
    endif()

    # Default CMAKE_COMMAND
    if (NOT DEFINED gba_external_project_add_CMAKE_COMMAND)
        set(gba_external_project_add_CMAKE_COMMAND ${CMAKE_COMMAND})
    endif()

    # Default CMAKE_CACHE_ARGS
    file(TO_CMAKE_PATH "${CMAKE_TOOLCHAIN_FILE}" ToolchainFile)
    list(APPEND gba_external_project_add_CMAKE_CACHE_ARGS -DCMAKE_TOOLCHAIN_FILE:PATH=${ToolchainFile})

    ExternalProject_Add(${name}
            SOURCE_DIR ${gba_external_project_add_SOURCE_DIR}
            BINARY_DIR ${gba_external_project_add_BINARY_DIR}
            INSTALL_COMMAND ${gba_external_project_add_INSTALL_COMMAND}
            CMAKE_COMMAND ${gba_external_project_add_CMAKE_COMMAND}
            CMAKE_ARGS ${gba_external_project_add_CMAKE_ARGS}
            CMAKE_CACHE_ARGS ${gba_external_project_add_CMAKE_CACHE_ARGS}
            CMAKE_CACHE_DEFAULT_ARGS ${gba_external_project_add_CMAKE_CACHE_DEFAULT_ARGS}
            )
endfunction()
