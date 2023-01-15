include(ExternalProject)

find_library(libtonc tonc PATHS "$ENV{DEVKITPRO}/libtonc/lib" "${CMAKE_SYSTEM_LIBRARY_PATH}/tonclib/lib")

if(NOT libtonc)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/tonclib")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/include")
    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    file(WRITE "${SOURCE_DIR}/temp/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(tonclib ASM C)

        file(GLOB sources "asm/*.s" "src/*.c" "src/*.s" "src/font/*.s" "src/tte/*.c" "src/tte/*.s" "src/pre1.3/*.c" "src/pre1.3/*.s")
        get_filename_component(iohook "${CMAKE_CURRENT_SOURCE_DIR}/src/tte/tte_iohook.c" ABSOLUTE)
        list(REMOVE_ITEM sources "${iohook}")

        add_library(tonc STATIC ${sources})
        target_include_directories(tonc SYSTEM PUBLIC include)

        target_compile_options(tonc PRIVATE
            -mthumb
            $<$<COMPILE_LANGUAGE:ASM>:-x assembler-with-cpp>
            $<$<COMPILE_LANGUAGE:C>:-ffunction-sections -fdata-sections -Wall -Wextra -Wno-unused-parameter -Wno-char-subscripts -Wno-sign-compare -Wno-implicit-fallthrough -Wno-type-limits>
        )

        install(TARGETS tonc
            LIBRARY DESTINATION lib
        )
        install(DIRECTORY include/
            DESTINATION include
        )
    ]=])

    ExternalProject_Add(libtonc
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/devkitPro/libtonc.git"
        GIT_TAG "master"
        # Update
        UPDATE_COMMAND "${CMAKE_COMMAND}" -E copy
            "${SOURCE_DIR}/temp/CMakeLists.txt"
            "${SOURCE_DIR}/source/CMakeLists.txt"
        # Configure
        SOURCE_DIR "${SOURCE_DIR}/source"
        CMAKE_ARGS --toolchain "${CMAKE_TOOLCHAIN_FILE}"
            -DCMAKE_INSTALL_PREFIX:PATH='${SOURCE_DIR}'
            -DCMAKE_BUILD_TYPE:STRING='${CMAKE_BUILD_TYPE}'
        # Build
        BINARY_DIR "${SOURCE_DIR}/build"
        BUILD_COMMAND "${CMAKE_COMMAND}" --build .
        BUILD_BYPRODUCTS "${SOURCE_DIR}/build/libtonc.a"
        # Install
        INSTALL_DIR "${SOURCE_DIR}"
    )

    add_library(tonclib STATIC IMPORTED)
    add_dependencies(tonclib libtonc)
    set_property(TARGET tonclib PROPERTY IMPORTED_LOCATION "${SOURCE_DIR}/build/libtonc.a")
    target_include_directories(tonclib INTERFACE "${SOURCE_DIR}/include")
else()
    add_library(tonclib STATIC IMPORTED)
    set_property(TARGET tonclib PROPERTY IMPORTED_LOCATION "${libtonc}")

    get_filename_component(INCLUDE_PATH "${libtonc}" DIRECTORY)
    get_filename_component(INCLUDE_PATH "${INCLUDE_PATH}" DIRECTORY)
    target_include_directories(tonclib INTERFACE "${INCLUDE_PATH}/include")
endif()

unset(libtonc CACHE)
