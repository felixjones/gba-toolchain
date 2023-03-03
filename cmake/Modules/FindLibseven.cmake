include(ExternalProject)

find_library(libseven seven PATHS "$ENV{DEVKITPRO}/libseven" "${CMAKE_SYSTEM_LIBRARY_PATH}/libseven" "${LIBSEVEN_DIR}" PATH_SUFFIXES lib)

if(NOT libseven)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/libseven")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/include")

    ExternalProject_Add(libseven_proj
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/LunarLambda/sdk-seven.git"
        GIT_TAG "main"
        # Configure
        SOURCE_DIR "${SOURCE_DIR}/source"
        SOURCE_SUBDIR "libseven"
        CMAKE_ARGS --toolchain "${CMAKE_TOOLCHAIN_FILE}"
            -DCMAKE_INSTALL_PREFIX:PATH='${SOURCE_DIR}'
        # Build
        BINARY_DIR "${SOURCE_DIR}/build"
        BUILD_COMMAND "${CMAKE_COMMAND}" --build .
        BUILD_BYPRODUCTS "${SOURCE_DIR}/build/libseven.a"
        # Install
        INSTALL_DIR "${SOURCE_DIR}"
    )

    add_library(libseven STATIC IMPORTED)
    add_dependencies(libseven libseven_proj)
    set_property(TARGET libseven PROPERTY IMPORTED_LOCATION "${SOURCE_DIR}/build/libseven.a")
    target_include_directories(libseven INTERFACE "${SOURCE_DIR}/include")
else()
    add_library(libseven STATIC IMPORTED)
    set_property(TARGET libseven PROPERTY IMPORTED_LOCATION "${libseven}")

    get_filename_component(INCLUDE_PATH "${libseven}" DIRECTORY)
    get_filename_component(INCLUDE_PATH "${INCLUDE_PATH}" DIRECTORY)
    target_include_directories(libseven INTERFACE "${INCLUDE_PATH}/include")
endif()

unset(libseven CACHE)
