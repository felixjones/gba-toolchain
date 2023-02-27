include(ExternalProject)

find_library(libgba gba PATHS "$ENV{DEVKITPRO}/libgba/lib" "${LIBGBA_DIR}")

if(NOT libgba)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/libgba")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/include")
    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    file(WRITE "${SOURCE_DIR}/temp/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(libgba ASM C)

        file(GLOB sources "src/*.c" "src/*.s" "src/BoyScout/*.c" "src/disc_io/*.c" "src/disc_io/*.s")
        get_filename_component(console "${CMAKE_CURRENT_SOURCE_DIR}/src/console.c" ABSOLUTE)
        list(REMOVE_ITEM sources "${console}")

        add_library(gba STATIC ${sources})
        target_include_directories(gba SYSTEM PUBLIC include)

        target_compile_options(gba PRIVATE
            $<$<COMPILE_LANGUAGE:ASM>:-x assembler-with-cpp>
            $<$<COMPILE_LANGUAGE:C>:-mthumb -O2
                -fno-strict-aliasing
                -fomit-frame-pointer
                -ffunction-sections
                -fdata-sections
                -Wall
                -Wextra
                -Wno-unused-parameter
                -Wno-sign-compare
                -Wno-old-style-declaration
                -Wno-discarded-qualifiers
                -Wno-multichar
            >
        )

        install(TARGETS gba
            LIBRARY DESTINATION lib
        )
        install(DIRECTORY include/
            DESTINATION include
        )
    ]=])

    ExternalProject_Add(libgba_proj
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/devkitPro/libgba.git"
        GIT_TAG "master"
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
        BUILD_BYPRODUCTS "${SOURCE_DIR}/build/libgba.a"
        # Install
        INSTALL_DIR "${SOURCE_DIR}"
    )

    add_library(libgba STATIC IMPORTED)
    add_dependencies(libgba libgba_proj)
    set_property(TARGET libgba PROPERTY IMPORTED_LOCATION "${SOURCE_DIR}/build/libgba.a")
    target_include_directories(libgba INTERFACE "${SOURCE_DIR}/include")
else()
    add_library(libgba STATIC IMPORTED)
    set_property(TARGET libgba PROPERTY IMPORTED_LOCATION "${libgba}")

    get_filename_component(INCLUDE_PATH "${libgba}" DIRECTORY)
    get_filename_component(INCLUDE_PATH "${INCLUDE_PATH}" DIRECTORY)
    target_include_directories(libgba INTERFACE "${INCLUDE_PATH}/include")
endif()

unset(libgba CACHE)
