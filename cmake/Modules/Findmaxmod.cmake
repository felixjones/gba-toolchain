#===============================================================================
#
# Finds MaxMod and provides the `add_maxmod_library` function
#   If MaxMod is not available, it will be downloaded and compiled.
#   `add_maxmod_library` compiles mod files into an object library to be linked.
#
# Multiple MaxMod libraries may be linked together to produce a single soundbank.
#
# MaxMod libraries have the following properties:
#   `MAXMOD_SOURCES` list of source paths relative to `CMAKE_CURRENT_SOURCE_DIR`.
#
# When passing sources directly to `add_maxmod_library` the GENERATED flag will be checked
# this allows MaxMod libraries to be built with generated files (such as from `add_s3msplit_command`)
#
# MaxMod libraries also provide an INTERFACE link to libmm for convenience.
# MaxMod libraries will generate a header file for convenience.
#
# Example:
#   ```cmake
#   add_maxmod_library(soundbank
#        maxmod_data/Ambulance.wav
#        maxmod_data/Boom.wav
#        maxmod_data/FlatOutLies.mod
#   )
#   target_link_libraries(my_target PRIVATE soundbank)
#   ```
#
# Add MaxMod library command:
#   `add_maxmod_library(<target> <file-path>...)`
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

if(TARGET maxmod)
    return()
endif()

#TODO: add_mmutil_command

function(add_maxmod_library target)
    set(maxmodTargetDir "_maxmod/${target}.dir")
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${maxmodTargetDir}")

    if(CMAKE_VERSION VERSION_LESS 3.27)
        set(sourcesEval $<TARGET_PROPERTY:${target},INTERFACE_SOURCES>)
    else()
        set(sourcesEval $<TARGET_PROPERTY:${target},MAXMOD_SOURCES>)
    endif()
    set(commandSourcesEval "$<IF:$<VERSION_GREATER_EQUAL:${CMAKE_VERSION},3.27>,$<PATH:ABSOLUTE_PATH,NORMALIZE,${sourcesEval},${CMAKE_CURRENT_SOURCE_DIR}>,${sourcesEval}>")

    add_custom_command(OUTPUT "${maxmodTargetDir}/${target}.o" "${maxmodTargetDir}/${target}.h" "${maxmodTargetDir}/${target}_bin.h"
            DEPENDS ${commandSourcesEval}
            # Run mmutil
            COMMAND "${MMUTIL_PATH}" -o${target}.bin -h${target}.h ${commandSourcesEval} > $<IF:$<BOOL:${CMAKE_HOST_WIN32}>,NUL,/dev/null>
            # Create object file
            COMMAND "${CMAKE_COMMAND}" -D "CMAKE_LINKER=\"${CMAKE_LINKER}\"" -D "CMAKE_OBJCOPY=\"${CMAKE_OBJCOPY}\""
                -P "${BIN2O_PATH}" -- "${target}.o" HEADER "${target}_bin.h" "${target}.bin"
            # Remove byproducts
            COMMAND "${CMAKE_COMMAND}" -E rm -f "${target}.bin"
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${maxmodTargetDir}"
            COMMAND_EXPAND_LISTS
    )

    unset(sources)
    foreach(arg ${ARGN})
        if(IS_ABSOLUTE "${arg}" AND EXISTS "${arg}")
            list(APPEND sources "${arg}")
            continue()
        endif()

        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${arg}")
            list(APPEND sources "${arg}")
            continue()
        endif()

        get_source_file_property(isGenerated "${arg}" GENERATED)
        if(isGenerated)
            if(IS_ABSOLUTE "${arg}")
                list(APPEND sources "${arg}")
                continue()
            endif()

            list(APPEND sources "${CMAKE_CURRENT_BINARY_DIR}/${arg}")
            continue()
        endif()

        message(FATAL_ERROR "Cannot find source file: ${arg}")
    endforeach()

    add_library(${target} OBJECT IMPORTED)
    set_target_properties(${target} PROPERTIES
            IMPORTED_OBJECTS "${CMAKE_CURRENT_BINARY_DIR}/${maxmodTargetDir}/${target}.o"
            MAXMOD_SOURCES "${sources}"
    )
    if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.27)
        target_sources(${target}
                INTERFACE "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<TARGET_PROPERTY:${target},MAXMOD_SOURCES>,${CMAKE_CURRENT_SOURCE_DIR}>"
        )
    endif()
    target_include_directories(${target} INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/${maxmodTargetDir}")
    target_link_libraries(${target} INTERFACE maxmod)
endfunction()

include(FetchContent)
include(Mktemp)

find_library(MAXMOD_PATH mm
        PATHS ${devkitARM} "${MAXMOD_DIR}"
        PATH_SUFFIXES "lib" "libgba/lib"
)

if(MAXMOD_PATH)
    add_library(maxmod STATIC IMPORTED)
    set_target_properties(maxmod PROPERTIES IMPORTED_LOCATION "${MAXMOD_PATH}")

    get_filename_component(maxmodPath "${MAXMOD_PATH}" DIRECTORY)
    get_filename_component(maxmodPath "${maxmodPath}" DIRECTORY)
    if(EXISTS "${maxmodPath}/include/maxmod.h")
        target_include_directories(maxmod INTERFACE "${maxmodPath}/include")
    endif()
else()
    mktemp(maxmodCMakeLists TMPDIR)
    file(WRITE "${maxmodCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(maxmod VERSION 1.0.13 LANGUAGES ASM)

file(GLOB sources CONFIGURE_DEPENDS "source/*.s" "source_gba/*.s")

add_library(maxmod STATIC ${sources})
set_target_properties(maxmod PROPERTIES OUTPUT_NAME "mm")
target_include_directories(maxmod
    INTERFACE include
    PRIVATE asm_include
)

target_compile_options(maxmod PRIVATE -x assembler-with-cpp)
target_compile_definitions(maxmod PRIVATE SYS_GBA USE_IWRAM)
]=])

    FetchContent_Declare(maxmodlib
            GIT_REPOSITORY "https://github.com/devkitPro/maxmod.git"
            GIT_TAG "master"
            PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${maxmodCMakeLists}" "CMakeLists.txt"
    )
    FetchContent_MakeAvailable(maxmodlib)

    file(REMOVE "${maxmodCMakeLists}")
endif()

find_program(MMUTIL_PATH mmutil mmutil.exe
        PATHS ${devkitARM} "${MMUTIL_DIR}" $ENV{HOME}
        PATH_SUFFIXES "bin" "tools/bin"
)

if(MMUTIL_PATH)
    return()
endif()

mktemp(mmutilCMakeLists TMPDIR)
file(WRITE "${mmutilCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(mmutil VERSION 1.10.1 LANGUAGES C)

file(GLOB sources CONFIGURE_DEPENDS "source/*.c")

add_executable(mmutil ${sources})
target_compile_options(mmutil PRIVATE -Wno-multichar)
target_compile_definitions(mmutil PRIVATE PACKAGE_VERSION="${CMAKE_PROJECT_VERSION}")
if(NOT WIN32)
    target_link_libraries(mmutil PRIVATE m)
endif()
install(TARGETS mmutil DESTINATION bin)
]=])

include(ProcessorCount)

FetchContent_Declare(mmutil
        GIT_REPOSITORY "https://github.com/devkitPro/mmutil.git"
        GIT_TAG "master"
)

FetchContent_GetProperties(mmutil)
if(NOT mmutil_POPULATED)
    FetchContent_Populate(mmutil)
    execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${mmutilCMakeLists}" "${mmutil_SOURCE_DIR}/CMakeLists.txt")
    file(REMOVE "${mmutilCMakeLists}")

    if(CMAKE_C_COMPILER_LAUNCHER)
        list(APPEND cmakeFlags -D CMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER})
    endif()
    if(CMAKE_CXX_COMPILER_LAUNCHER)
        list(APPEND cmakeFlags -D CMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER})
    endif()
    ProcessorCount(nproc)
    math(EXPR nproc "${nproc} - 1")

    execute_process(COMMAND "${CMAKE_COMMAND}" -S "${mmutil_SOURCE_DIR}" -B "${mmutil_BINARY_DIR}" -G "${CMAKE_GENERATOR}" ${cmakeFlags})  # Configure
    execute_process(COMMAND "${CMAKE_COMMAND}" --build "${mmutil_BINARY_DIR}" --parallel ${nproc})  # Build
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
        execute_process(COMMAND "${CMAKE_COMMAND}" --install "${mmutil_BINARY_DIR}" --prefix $ENV{HOME})  # Install
    endif()

    find_program(MMUTIL_PATH mmutil mmutil.exe PATHS "${mmutil_BINARY_DIR}")
else()
    file(REMOVE "${mmutilCMakeLists}")
endif()
