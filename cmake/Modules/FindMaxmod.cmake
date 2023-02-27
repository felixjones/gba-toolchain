include(ExternalProject)

find_library(libmm mm PATHS "$ENV{DEVKITPRO}/libgba/lib" "${MAXMOD_DIR}")

if(NOT libmm)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/maxmod")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/include")
    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    file(WRITE "${SOURCE_DIR}/temp/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(maxmod ASM)

        file(GLOB sources "source/*.s" "source_gba/*.s")

        add_library(maxmod STATIC ${sources})
        set_target_properties(maxmod PROPERTIES OUTPUT_NAME "mm")
        target_include_directories(maxmod SYSTEM PUBLIC include PRIVATE asm_include)

        target_compile_options(maxmod PRIVATE
            -DSYS_GBA -DUSE_IWRAM
            $<$<COMPILE_LANGUAGE:ASM>:-x assembler-with-cpp>
            $<$<COMPILE_LANGUAGE:C>:-mthumb -O2
                -fno-strict-aliasing
                -fomit-frame-pointer
                -ffunction-sections
                -fdata-sections
                -Wall
                -Wextra
            >
        )

        install(TARGETS maxmod
            LIBRARY DESTINATION lib
        )
        install(DIRECTORY include/
            DESTINATION include
        )
    ]=])

    ExternalProject_Add(maxmod_proj
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/devkitPro/maxmod.git"
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
        BUILD_BYPRODUCTS "${SOURCE_DIR}/build/libmm.a"
        # Install
        INSTALL_DIR "${SOURCE_DIR}"
    )

    add_library(maxmod STATIC IMPORTED)
    add_dependencies(maxmod maxmod_proj)
    set_property(TARGET maxmod PROPERTY IMPORTED_LOCATION "${SOURCE_DIR}/build/libmm.a")
    target_include_directories(maxmod INTERFACE "${SOURCE_DIR}/include")
else()
    add_library(maxmod STATIC IMPORTED)
    set_property(TARGET maxmod PROPERTY IMPORTED_LOCATION "${libmm}")

    get_filename_component(INCLUDE_PATH "${libmm}" DIRECTORY)
    get_filename_component(INCLUDE_PATH "${INCLUDE_PATH}" DIRECTORY)
    target_include_directories(maxmod INTERFACE "${INCLUDE_PATH}/include")
endif()

unset(libmm CACHE)
