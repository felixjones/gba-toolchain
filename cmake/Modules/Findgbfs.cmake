#===============================================================================
#
# Finds gbfs and provides the `add_gbfs_library` function
#   The gbfs library will be downloaded and compiled.
#
# CMake usage:
#   `add_gbfs_library(<target> <file-path>...)`
#
# GBFS libraries can be linked to executable and library targets.
# GBFS libraries also provide an INTERFACE link to libgbfs for convenience.
# GBFS libraries will generate a header file for convenience.
# The GBFS start symbol will be kept to allow `find_first_gbfs_file` support.
# The GBFS start symbol will be on a 256 byte alignment.
#
# GBFS libraries have the following properties:
#   `GBFS_SOURCES` list of asset files.
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

function(add_gbfs_library target)
    set(gbfsTargetDir "_gbfs/${target}.dir")
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${gbfsTargetDir}")
    set(sourcesEval $<TARGET_PROPERTY:${target},INTERFACE_SOURCES>)

    add_custom_command(OUTPUT "${gbfsTargetDir}/${target}.o" "${gbfsTargetDir}/${target}.h"
            DEPENDS $<PATH:ABSOLUTE_PATH,NORMALIZE,${sourcesEval},${CMAKE_CURRENT_SOURCE_DIR}>
            # Run gbfs
            COMMAND "${GBFS_PATH}" "${target}.gbfs" $<PATH:ABSOLUTE_PATH,NORMALIZE,${sourcesEval},${CMAKE_CURRENT_SOURCE_DIR}>
                > $<IF:$<BOOL:${CMAKE_HOST_WIN32}>,NUL,/dev/null>
            # Create object file
            COMMAND "${CMAKE_COMMAND}" -D "CMAKE_LINKER=\"${CMAKE_LINKER}\"" -D "CMAKE_OBJCOPY=\"${CMAKE_OBJCOPY}\""
                -P "${BIN2O_PATH}" -- "${target}.o" HEADER "${target}.h" ALIGNMENT 256 "${target}.gbfs"
            # Remove byproducts
            COMMAND "${CMAKE_COMMAND}" -E rm -f "${target}.gbfs"
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${gbfsTargetDir}"
    )

    add_library(${target} OBJECT IMPORTED)
    set_target_properties(${target} PROPERTIES
            IMPORTED_OBJECTS "${CMAKE_CURRENT_BINARY_DIR}/${gbfsTargetDir}/${target}.o"
            GBFS_SOURCES "${ARGN}"
    )
    target_sources(${target}
            INTERFACE "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<TARGET_PROPERTY:${target},GBFS_SOURCES>,${CMAKE_CURRENT_SOURCE_DIR}>"
    )
    target_include_directories(${target} INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/${gbfsTargetDir}")
    target_link_libraries(${target} INTERFACE gbfs)

    # Keep the Start symbol
    target_link_options(${target} INTERFACE "-Wl,--undefined=${target}_gbfs")
endfunction()

include(FetchContent)
include(Mktemp)
include(ProcessorCount)

if(NOT TARGET gbfs)
    mktemp(gbfsCMakeLists TMPDIR)
    file(WRITE "${gbfsCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(gbfs C)

if(GBA)
    add_library(gbfs STATIC libgbfs.c)
    target_include_directories(gbfs
        INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}
    )
else()
    add_executable(gbfs tools/gbfs.c $<$<BOOL:${MSVC}>:tools/djbasename.c>)
    install(TARGETS gbfs DESTINATION bin)
endif()
]=])

    FetchContent_Declare(gbfs
            URL "https://pineight.com/gba/gbfs.zip"
            PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${gbfsCMakeLists}" "CMakeLists.txt"
    )
    FetchContent_MakeAvailable(gbfs)

    file(REMOVE "${gbfsCMakeLists}")
endif()

find_program(GBFS_PATH gbfs gbfs.exe
        PATHS ${devkitARM} "${GBFS_DIR}" $ENV{HOME}
        PATH_SUFFIXES "bin" "tools/bin"
)

if(GBFS_PATH)
    return()
endif()

if(CMAKE_C_COMPILER_LAUNCHER)
    list(APPEND cmakeFlags -D CMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER})
endif()
if(CMAKE_CXX_COMPILER_LAUNCHER)
    list(APPEND cmakeFlags -D CMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER})
endif()
ProcessorCount(nproc)
math(EXPR nproc "${nproc} - 1")

execute_process(COMMAND "${CMAKE_COMMAND}" -S "${gbfs_SOURCE_DIR}" -B "${gbfs_BINARY_DIR}" -G "${CMAKE_GENERATOR}" ${cmakeFlags})  # Configure
execute_process(COMMAND "${CMAKE_COMMAND}" --build "${gbfs_BINARY_DIR}" --parallel ${nproc})  # Build
if(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
    execute_process(COMMAND "${CMAKE_COMMAND}" --install "${gbfs_BINARY_DIR}" --prefix $ENV{HOME})  # Install
endif()

find_program(GBFS_PATH gbfs gbfs.exe PATHS "${gbfs_BINARY_DIR}")
