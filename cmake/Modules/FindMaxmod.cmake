include(ExternalProject)

find_library(libmm mm PATHS "$ENV{DEVKITPRO}/libgba" "${CMAKE_SYSTEM_LIBRARY_PATH}/maxmod" "${MAXMOD_DIR}" PATH_SUFFIXES lib)

if(NOT libmm)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/maxmod")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/include")
    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    file(WRITE "${SOURCE_DIR}/temp/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)
        project(maxmod ASM)

        add_library(maxmod STATIC
            source/mm_effect.s
            source/mm_main.s
            source/mm_mas.s
            source/mm_mas_arm.s
            source_gba/mm_init_default.s
            source_gba/mm_main_gba.s
            source_gba/mm_mixer_gba.s
        )
        set_target_properties(maxmod PROPERTIES OUTPUT_NAME "mm")

        target_include_directories(maxmod SYSTEM PUBLIC include/)
        target_include_directories(maxmod PRIVATE asm_include/)
        target_compile_definitions(maxmod PRIVATE SYS_GBA USE_IWRAM)
        target_compile_options(maxmod PRIVATE -x assembler-with-cpp)

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

find_program(CMAKE_MMUTIL_PROGRAM mmutil PATHS "$ENV{DEVKITPRO}/tools" "${CMAKE_SYSTEM_LIBRARY_PATH}/maxmod" "${MMUTIL_DIR}" PATH_SUFFIXES bin)

if(NOT CMAKE_MMUTIL_PROGRAM)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/maxmod")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp/mmutil")
    file(WRITE "${SOURCE_DIR}/temp/mmutil/CMakeLists.txt" [=[
        cmake_minimum_required(VERSION 3.18)

        project(mmutil C)

        add_executable(mmutil
            source/adpcm.c
            source/files.c source/gba.c
            source/it.c source/kiwi.c source/main.c source/mas.c
            source/mod.c source/msl.c source/nds.c
            source/s3m.c source/samplefix.c
            source/simple.c source/upload.c
            source/wav.c source/xm.c
        )

        target_include_directories(mmutil PRIVATE source)
        target_compile_definitions(mmutil PRIVATE PACKAGE_VERSION="1.9.1")

        if(NOT MSVC)
            target_link_libraries(mmutil PRIVATE m)
        endif()

        install(TARGETS mmutil DESTINATION bin)
    ]=])

    FetchContent_Declare(mmutil_proj DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp/mmutil"
        STAMP_DIR "${SOURCE_DIR}/stamp/mmutil"
        SOURCE_DIR "${SOURCE_DIR}/source/mmutil"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download/mmutil"
        GIT_REPOSITORY "https://github.com/devkitPro/mmutil.git"
        GIT_TAG "master"
        # Update
        UPDATE_COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${SOURCE_DIR}/temp/mmutil/CMakeLists.txt"
            "${SOURCE_DIR}/source/mmutil/CMakeLists.txt"
    )

    FetchContent_MakeAvailable(mmutil_proj)

    # Configure
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -S . -B "${SOURCE_DIR}/build/mmutil"
        WORKING_DIRECTORY "${SOURCE_DIR}/source/mmutil"
        RESULT_VARIABLE cmakeResult
    )

    if(cmakeResult EQUAL "1")
        message(WARNING "Failed to configure mmutil")
    else()
        # Build
        execute_process(
            COMMAND "${CMAKE_COMMAND}" --build . --config Release
            WORKING_DIRECTORY "${SOURCE_DIR}/build/mmutil"
            RESULT_VARIABLE cmakeResult
        )

        if(cmakeResult EQUAL "1")
            message(WARNING "Failed to build mmutil")
        else()
            # Install
            execute_process(
                COMMAND ${CMAKE_COMMAND} --install . --prefix "${SOURCE_DIR}" --config Release
                WORKING_DIRECTORY "${SOURCE_DIR}/build/mmutil"
                RESULT_VARIABLE cmakeResult
            )

            if(cmakeResult EQUAL "1")
                message(WARNING "Failed to install mmutil")
            else()
                find_program(CMAKE_MMUTIL_PROGRAM mmutil PATHS "${SOURCE_DIR}/bin")
            endif()
        endif()
    endif()
endif()

if(NOT CMAKE_MMUTIL_PROGRAM)
    message(WARNING "mmutil not found: Please set `-DCMAKE_MMUTIL_PROGRAM:FILEPATH=<path/to/bin/mmutil>`")
endif()

function(add_maxmod_soundbank target)
    cmake_parse_arguments(ARGS "" "" "" ${ARGN})

    string(CONCAT TARGET_FILE
        $<TARGET_PROPERTY:${target},OUTPUT_DIRECTORY>
        /
        $<TARGET_PROPERTY:${target},PREFIX>
        $<TARGET_PROPERTY:${target},OUTPUT_NAME>
        $<TARGET_PROPERTY:${target},SUFFIX>
    )
    string(CONCAT TARGET_INCLUDE_DIR
        $<TARGET_PROPERTY:${target},OUTPUT_DIRECTORY>
        /include/
    )
    string(CONCAT TARGET_HEADER
        ${TARGET_INCLUDE_DIR}
        $<TARGET_PROPERTY:${target},PREFIX>
        $<TARGET_PROPERTY:${target},OUTPUT_NAME>
        .h
    )

    set(SOURCES $<TARGET_PROPERTY:${target},SOURCES>)

    string(REGEX REPLACE "([][+.*()^])" "\\\\\\1" SOURCES_BUG_FIX "${CMAKE_BINARY_DIR}/CMakeFiles/${target}")

    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/_stamp")
    set(STAMP "${CMAKE_BINARY_DIR}/_stamp/${target}.stamp")

    add_custom_command(OUTPUT ${STAMP}
        COMMAND "${CMAKE_COMMAND}" -E make_directory ${TARGET_INCLUDE_DIR}
        COMMAND "${CMAKE_MMUTIL_PROGRAM}" -o${TARGET_FILE} -h${TARGET_HEADER} $<FILTER:${SOURCES},EXCLUDE,${SOURCES_BUG_FIX}|[.]rule>
        COMMAND "${CMAKE_COMMAND}" -E touch ${STAMP}
        DEPENDS $<FILTER:${SOURCES},EXCLUDE,${SOURCES_BUG_FIX}|[.]rule>
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        VERBATIM
        COMMAND_EXPAND_LISTS
    )

    add_custom_target(${target} DEPENDS ${STAMP})

    set_target_properties(${target} PROPERTIES
        OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        OUTPUT_NAME "${target}"
        SUFFIX ".bin"
        TARGET_FILE ${TARGET_FILE}
        TARGET_INCLUDE_DIR ${TARGET_INCLUDE_DIR}
    )

    if(ARGS_UNPARSED_ARGUMENTS)
        set_target_properties(${target} PROPERTIES
            SOURCES "${ARGS_UNPARSED_ARGUMENTS}"
        )
    endif()
endfunction()
