#===============================================================================
#
# GBA Platform
#   Provides asset library support
#
# Asset libraries have the following properties:
#   `ASSET_WORKING_DIRECTORY` base directory of the assets.
#   `ASSET_SOURCES` list of asset files.
#   `ASSET_PREFIX` prefix for asset symbols.
#   `ASSET_SUFFIX_START` suffix for asset start symbol.
#   `ASSET_SUFFIX_END` suffix for asset end symbol.
#   `ASSET_SUFFIX_SIZE` suffix for asset size symbol.
#
# CMake usage:
#   `add_asset_library(<target> [PREFIX <symbol-prefix>] [SUFFIX_START <start-symbol-suffix>] [SUFFIX_END <end-symbol-suffix>] [SUFFIX_SIZE <size-symbol-suffix>] [WORKING_DIRECTORY <working-directory-path>] <file-path>...)`
#
# Asset libraries can be linked to executable and library targets.
# Provides the `ASSETS` target property for a list of compiled assets.
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include(Platform/Generic-ELF)

set(GBA 1)

# Setup default install prefix
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_SOURCE_DIR}" CACHE PATH "Installation prefix path for the project install step" FORCE)
endif()

include(Bin2o)
include(Depfile)

function(add_asset_library target)
    set(assetsTargetDir "_assets/${target}.dir")
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${assetsTargetDir}")
    set(workingDirectory "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<TARGET_PROPERTY:${target},ASSET_WORKING_DIRECTORY>,${CMAKE_CURRENT_SOURCE_DIR}>")
    set(sourcesEval $<TARGET_PROPERTY:${target},ASSET_SOURCES>)

    set(oneValueArgs PREFIX SUFFIX_START SUFFIX_END SUFFIX_SIZE WORKING_DIRECTORY)
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "" ${ARGN})
    if(NOT ARGS_UNPARSED_ARGUMENTS)
        set(ARGS_UNPARSED_ARGUMENTS "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()

    set(bin2oArgs
            "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_PREFIX>>:PREFIX>" "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_PREFIX>>:$<TARGET_PROPERTY:${target},ASSET_PREFIX>>"
            "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_START>>:SUFFIX_START>" "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_START>>:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_START>>"
            "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_END>>:SUFFIX_END>" "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_END>>:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_END>>"
            "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_SIZE>>:SUFFIX_SIZE>" "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_SIZE>>:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_SIZE>>"
    )

    add_library(${target} OBJECT IMPORTED)

    unset(sources)
    unset(targetSources)
    foreach(arg ${ARGS_UNPARSED_ARGUMENTS})
        if(TARGET ${arg})
            get_target_property(type ${arg} TYPE)
            if (type STREQUAL "EXECUTABLE")
                list(APPEND targetSources "$<TARGET_FILE:${arg}>")
                add_dependencies(${target} ${arg})
                continue()
            endif()

            message(FATAL_ERROR "Unsupported target type ${type}")
        endif()

        if(NOT EXISTS ${arg})
            if(NOT IS_ABSOLUTE "${arg}")
                set(arg "${CMAKE_CURRENT_BINARY_DIR}/${arg}")
            endif()
            set_source_files_properties("${arg}" PROPERTIES GENERATED TRUE)
            list(APPEND sources "${arg}")
            continue()
        endif()

        list(APPEND sources "$<PATH:ABSOLUTE_PATH,NORMALIZE,${arg},${CMAKE_CURRENT_SOURCE_DIR}>")
    endforeach()

    add_custom_command(OUTPUT "${assetsTargetDir}/${target}.o" "${assetsTargetDir}/${target}.h"
            DEPFILE "${assetsTargetDir}/${target}.d"
            COMMAND "${CMAKE_COMMAND}" -P "${DEPFILE_PATH}" -- "${CMAKE_CURRENT_BINARY_DIR}/${assetsTargetDir}/${target}.d"
                TARGETS "${assetsTargetDir}/${target}.o" "${assetsTargetDir}/${target}.h" DEPENDENCIES $<PATH:ABSOLUTE_PATH,NORMALIZE,${sourcesEval},${workingDirectory}> ${targetSources}
            COMMAND "${CMAKE_COMMAND}" -D "CMAKE_LINKER=\"${CMAKE_LINKER}\"" -D "CMAKE_OBJCOPY=\"${CMAKE_OBJCOPY}\""
                -P "${BIN2O_PATH}" -- "${CMAKE_CURRENT_BINARY_DIR}/${assetsTargetDir}/${target}.o"
                    HEADER "${CMAKE_CURRENT_BINARY_DIR}/${assetsTargetDir}/${target}.h"
                    ${bin2oArgs}
                    ${sourcesEval} ${targetSources}
            COMMAND_EXPAND_LISTS
            WORKING_DIRECTORY "${workingDirectory}"
    )

    set_target_properties(${target} PROPERTIES
            IMPORTED_OBJECTS "${CMAKE_CURRENT_BINARY_DIR}/${assetsTargetDir}/${target}.o"
            ASSET_WORKING_DIRECTORY "${ARGS_WORKING_DIRECTORY}"
            ASSET_SOURCES "${sources}"
            ASSET_PREFIX "${ARGS_PREFIX}"
            ASSET_SUFFIX_START "${ARGS_SUFFIX_START}"
            ASSET_SUFFIX_END "${ARGS_SUFFIX_END}"
            ASSET_SUFFIX_SIZE "${ARGS_SUFFIX_SIZE}"
    )
    target_include_directories(${target} INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/${assetsTargetDir}")
endfunction()
