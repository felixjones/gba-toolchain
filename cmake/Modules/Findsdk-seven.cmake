#===============================================================================
#
# sdk-seven library
#   Provides both the runtime libraries, the `add_gbafix_target` command to perform the "gbafix" operation,
#   sdk-seven library, and the libutil utility library.
#
# gbafix target command:
#   `add_gbafix_target(<target> <executable-target>)`
#
# `add_gbafix_target` also uses target-properties:
#   `ROM_TITLE` 12 character name.
#   `ROM_ID` 4 character ID in UTTD format. The first character (U) suggests save-type*. The last character (D) suggests region/language**.
#   `ROM_MAKER` 2 character maker ID.
#   `ROM_VERSION` 1 byte numeric version (0-255).
#       *Known save types:
#           `1` EEPROM
#           `2` SRAM
#           `3` FLASH-64
#           `4` FLASH-128
#       **Known regions/languages:
#           `J` Japan
#           `P` Europe/Elsewhere
#           `F` French
#           `S` Spanish
#           `E` USA/English
#           `D` German
#           `I` Italian
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include(FetchContent)
include(Mktemp)
include(GbaFix)

if(runtime IN_LIST sdk-seven_FIND_COMPONENTS)
    mktemp(runtimeCMakeLists TMPDIR)
    file(WRITE "${runtimeCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(runtime ASM C)

set(sources
        src/gba/header.S
        src/gba/rt0.s

        src/c/exit.c
        src/c/fini.c
        src/c/init.c
        src/c/start.c
)

add_library(minrt STATIC ${sources})
target_link_options(minrt INTERFACE
        -specs=${CMAKE_CURRENT_SOURCE_DIR}/lib/nocrt0.specs
        -T "${CMAKE_CURRENT_SOURCE_DIR}/lib/ldscripts/rom.mem"
        -T "${CMAKE_CURRENT_SOURCE_DIR}/lib/ldscripts/gba.x"
)
#target_link_options(minrt PRIVATE "LINKER:--no-warn-rwx-segments")

add_library(minrt_mb STATIC ${sources})
target_compile_definitions(minrt_mb PRIVATE "MULTIBOOT")
target_link_options(minrt_mb INTERFACE
        -specs=${CMAKE_CURRENT_SOURCE_DIR}/lib/nocrt0.specs
        -T "${CMAKE_CURRENT_SOURCE_DIR}/lib/ldscripts/multiboot.mem"
        -T "${CMAKE_CURRENT_SOURCE_DIR}/lib/ldscripts/gba.x"
)
#target_link_options(minrt_mb PRIVATE "LINKER:--no-warn-rwx-segments")
]=])

    FetchContent_Declare(runtime
            GIT_REPOSITORY "https://github.com/sdk-seven/runtime.git"
            GIT_TAG "main"
            PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${runtimeCMakeLists}" "CMakeLists.txt"
    )
    FetchContent_MakeAvailable(runtime)

    file(REMOVE "${runtimeCMakeLists}")

    add_library(sdk-seven::minrt ALIAS minrt)
    add_library(sdk-seven::minrt_mb ALIAS minrt_mb)

    if(NOT Python_EXECUTABLE)
        find_package(Python COMPONENTS Interpreter)
    endif()

    find_file(PYGBAFIX_PATH gbafix.py PATHS "${runtime_SOURCE_DIR}/tools/src")

    function(add_gbafix_target target depends)
        # Get gbafix parameters
        macro(get_gbafix_parameters list)
            foreach(property TITLE ID MAKER VERSION)
                get_target_property(var ${depends} ROM_${property})
                if(var)
                    list(APPEND ${list} ${property} "${var}")
                endif()
            endforeach()
        endmacro()
        get_gbafix_parameters(params)

        if(params)
            # Run verify pass for the inputs
            gbafix(VERIFY ${params})
        endif()

        if(Python_EXECUTABLE AND PYGBAFIX_PATH)
            cmake_parse_arguments(PYARGS "" "TITLE;ID;MAKER;VERSION" "" ${params})
            add_custom_target(${target} DEPENDS ${depends}
                    COMMAND "${CMAKE_OBJCOPY}" -O binary "$<TARGET_FILE_NAME:${depends}>" "$<TARGET_FILE_BASE_NAME:${depends}>.bin"
                    COMMAND "${CMAKE_COMMAND}" -E copy_if_different "$<TARGET_FILE_BASE_NAME:${depends}>.bin" "${target}.gba"
                    COMMAND "${Python_EXECUTABLE}" "${PYGBAFIX_PATH}"
                        $<$<BOOL:${PYARGS_TITLE}>:--title=${PYARGS_TITLE}>
                        $<$<BOOL:${PYARGS_ID}>:--code=${PYARGS_ID}>
                        $<$<BOOL:${PYARGS_MAKER}>:--maker=${PYARGS_MAKER}>
                        $<$<BOOL:${PYARGS_VERSION}>:--revision=${PYARGS_VERSION}>
                        ${target}.gba
            )
        else()
            add_custom_target(${target} DEPENDS ${depends}
                    COMMAND "${CMAKE_OBJCOPY}" -O binary "$<TARGET_FILE_NAME:${depends}>" "$<TARGET_FILE_BASE_NAME:${depends}>.bin"
                    COMMAND "${CMAKE_COMMAND}" -P "${GBAFIX_PATH}" -- "$<TARGET_FILE_BASE_NAME:${depends}>.bin" "${params}" "$<TARGET_FILE_BASE_NAME:${depends}>.gba"
            )
        endif()
    endfunction()

endif()

if(libseven IN_LIST sdk-seven_FIND_COMPONENTS)
    mktemp(libsevenCMakeLists TMPDIR)
    file(WRITE "${libsevenCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(libseven ASM C)

file(GLOB sources CONFIGURE_DEPENDS "src/*.s" "src/*.c")

add_library(seven STATIC ${sources})

target_include_directories(seven PUBLIC include/)
target_include_directories(seven PRIVATE src/)

target_compile_options(seven PRIVATE
    $<$<COMPILE_LANGUAGE:C>:-O2 -g3 -gdwarf-4 -ffunction-sections -fdata-sections -std=c99 -Wall -Wextra -Wpedantic -mabi=aapcs -mcpu=arm7tdmi -mthumb -masm-syntax-unified>
)

set_source_files_properties("src/bios.c" PROPERTIES COMPILE_FLAGS "-Wno-pedantic")
]=])

    FetchContent_Declare(libseven
            GIT_REPOSITORY "https://github.com/sdk-seven/libseven.git"
            GIT_TAG "main"
            PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${libsevenCMakeLists}" "CMakeLists.txt"
    )

    FetchContent_GetProperties(libseven)
    if(NOT libseven_POPULATED)
        FetchContent_Populate(libseven)
        add_subdirectory(${libseven_SOURCE_DIR} ${libseven_BINARY_DIR} EXCLUDE_FROM_ALL)
    endif()

    file(REMOVE "${libsevenCMakeLists}")

    add_library(sdk-seven::libseven ALIAS seven)
endif()

if(libutil IN_LIST sdk-seven_FIND_COMPONENTS)
    mktemp(libutilCMakeLists TMPDIR)
    file(WRITE "${libutilCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(libutil ASM C)

file(GLOB sources CONFIGURE_DEPENDS "src/*.s" "src/*.c")

add_library(util STATIC ${sources})

target_include_directories(util PUBLIC include/)
target_include_directories(util PRIVATE src/)

target_compile_options(util PRIVATE
    $<$<COMPILE_LANGUAGE:C>:-masm-syntax-unified -Os -g3 -gdwarf-4 -ffunction-sections -fdata-sections -std=c99 -Wall -Wpedantic -mabi=aapcs -mcpu=arm7tdmi -mthumb>
)
]=])

    FetchContent_Declare(libutil
            GIT_REPOSITORY "https://github.com/sdk-seven/libutil.git"
            GIT_TAG "main"
            PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${libutilCMakeLists}" "CMakeLists.txt"
    )

    FetchContent_GetProperties(libutil)
    if(NOT libutil_POPULATED)
        FetchContent_Populate(libutil)
        add_subdirectory(${libutil_SOURCE_DIR} ${libutil_BINARY_DIR} EXCLUDE_FROM_ALL)
    endif()

    file(REMOVE "${libutilCMakeLists}")

    add_library(sdk-seven::libutil ALIAS util)
endif()