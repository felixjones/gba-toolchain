include(ExternalProject)

find_library(libagbabi agbabi PATHS "${CMAKE_SYSTEM_LIBRARY_PATH}/agbabi" "${AGBABI_DIR}" PATH_SUFFIXES lib)

if(NOT libagbabi)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/agbabi")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/include")

    ExternalProject_Add(libagbabi
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/felixjones/agbabi.git"
        GIT_TAG "v2.1.2"
        # Configure
        SOURCE_DIR "${SOURCE_DIR}/source"
        CMAKE_ARGS --toolchain "${CMAKE_TOOLCHAIN_FILE}"
            -DCMAKE_INSTALL_PREFIX:PATH='${SOURCE_DIR}'
            -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
        # Build
        BINARY_DIR "${SOURCE_DIR}/build"
        BUILD_COMMAND "${CMAKE_COMMAND}" --build .
        BUILD_BYPRODUCTS "${SOURCE_DIR}/build/libagbabi.a"
        # Install
        INSTALL_DIR "${SOURCE_DIR}"
    )

    add_library(agbabi STATIC IMPORTED)
    add_dependencies(agbabi libagbabi)
    set_property(TARGET agbabi PROPERTY IMPORTED_LOCATION "${SOURCE_DIR}/build/libagbabi.a")
    target_include_directories(agbabi INTERFACE "${SOURCE_DIR}/include")
else()
    add_library(agbabi STATIC IMPORTED)
    set_property(TARGET agbabi PROPERTY IMPORTED_LOCATION "${libagbabi}")

    get_filename_component(INCLUDE_PATH "${libagbabi}" DIRECTORY)
    get_filename_component(INCLUDE_PATH "${INCLUDE_PATH}" DIRECTORY)
    target_include_directories(agbabi INTERFACE "${INCLUDE_PATH}/include")
endif()

unset(libagbabi CACHE)
