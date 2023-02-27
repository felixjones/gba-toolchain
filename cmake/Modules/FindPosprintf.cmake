include(ExternalProject)

find_library(libposprintf posprintf PATHS "${CMAKE_SYSTEM_LIBRARY_PATH}/posprintf/lib" "${POSPRINTF_DIR}")

if(NOT libposprintf)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/posprintf")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/include")
    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    file(WRITE "${SOURCE_DIR}/temp/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(posprintf ASM)

        add_library(posprintf STATIC "posprintf/posprintf.S")

        install(TARGETS posprintf
            LIBRARY DESTINATION lib
        )
        install(FILES posprintf/posprintf.h
            DESTINATION include
        )
    ]=])

    ExternalProject_Add(posprintf_proj DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        URL "http://www.danposluns.com/gbadev/posprintf/posprintf.zip"
        URL_MD5 "f2cfce6b93764c59d84faa6c57ab1fbe"
        # Update
        UPDATE_COMMAND "${CMAKE_COMMAND}" -E copy
            "${SOURCE_DIR}/temp/CMakeLists.txt"
            "${SOURCE_DIR}/source/CMakeLists.txt"
        # Configure
        SOURCE_DIR "${SOURCE_DIR}/source"
        CMAKE_ARGS --toolchain "${CMAKE_TOOLCHAIN_FILE}"
            -DCMAKE_INSTALL_PREFIX:PATH='${SOURCE_DIR}'
        # Build
        BINARY_DIR "${SOURCE_DIR}/build"
        BUILD_COMMAND "${CMAKE_COMMAND}" --build .
        BUILD_BYPRODUCTS "${SOURCE_DIR}/build/libposprintf.a"
        # Install
        INSTALL_DIR "${SOURCE_DIR}"
    )

    add_library(posprintf STATIC IMPORTED)
    add_dependencies(posprintf posprintf_proj)
    set_property(TARGET posprintf PROPERTY IMPORTED_LOCATION "${SOURCE_DIR}/build/libposprintf.a")
    target_include_directories(posprintf INTERFACE "${SOURCE_DIR}/include")
else()
    add_library(posprintf STATIC IMPORTED)
    set_property(TARGET posprintf PROPERTY IMPORTED_LOCATION "${libposprintf}")

    get_filename_component(INCLUDE_PATH "${libposprintf}" DIRECTORY)
    get_filename_component(INCLUDE_PATH "${INCLUDE_PATH}" DIRECTORY)
    target_include_directories(posprintf INTERFACE "${INCLUDE_PATH}/include")
endif()

unset(libposprintf CACHE)
