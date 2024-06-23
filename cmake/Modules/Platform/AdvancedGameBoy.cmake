#===============================================================================
#
# GBA Platform
#   Provides asset library support
#
# Asset libraries have the following properties:
#   `ASSET_SOURCES` list of asset files.
#   `ASSET_PREFIX` prefix for asset symbols.
#   `ASSET_SUFFIX_START` suffix for asset start symbol.
#   `ASSET_SUFFIX_END` suffix for asset end symbol.
#   `ASSET_SUFFIX_SIZE` suffix for asset size symbol.
#
# CMake usage:
#   `add_asset_library(<target> [PREFIX <symbol-prefix>] [SUFFIX_START <start-symbol-suffix>] [SUFFIX_END <end-symbol-suffix>] [SUFFIX_SIZE <size-symbol-suffix>] <file-path>...)`
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

    if(CMAKE_VERSION VERSION_LESS 3.27)
        set(sourcesEval $<TARGET_PROPERTY:${target},INTERFACE_SOURCES>)
    else()
        set(sourcesEval $<TARGET_PROPERTY:${target},ASSET_SOURCES>)
    endif()
    set(commandSourcesEval "$<IF:$<VERSION_GREATER_EQUAL:${CMAKE_VERSION},3.27>,$<PATH:ABSOLUTE_PATH,NORMALIZE,${sourcesEval},${CMAKE_CURRENT_SOURCE_DIR}>,${sourcesEval}>")

    set(oneValueArgs PREFIX SUFFIX_START SUFFIX_END SUFFIX_SIZE)
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "" ${ARGN})

    set(bin2oArgs
            "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_PREFIX>>:PREFIX>" "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_PREFIX>>:$<TARGET_PROPERTY:${target},ASSET_PREFIX>>"
            "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_START>>:SUFFIX_START>" "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_START>>:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_START>>"
            "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_END>>:SUFFIX_END>" "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_END>>:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_END>>"
            "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_SIZE>>:SUFFIX_SIZE>" "$<$<BOOL:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_SIZE>>:$<TARGET_PROPERTY:${target},ASSET_SUFFIX_SIZE>>"
    )

    add_custom_command(OUTPUT "${assetsTargetDir}/${target}.o" "${assetsTargetDir}/${target}.h"
            DEPENDS ${commandSourcesEval}
            # Create object file
            COMMAND ${BIN2O_COMMAND} "${target}.o" HEADER "${target}.h" ${bin2oArgs} ${commandSourcesEval}
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${assetsTargetDir}"
            COMMAND_EXPAND_LISTS
    )

    unset(sources)
    foreach(arg ${ARGS_UNPARSED_ARGUMENTS})
        if(TARGET ${arg})
            get_target_property(type ${arg} TYPE)
            if (type STREQUAL "EXECUTABLE")
                list(APPEND sources "$<TARGET_FILE:${arg}>")
                add_dependencies(${target} ${arg})
                continue()
            endif()

            message(FATAL_ERROR "Unsupported target type ${type}")
        endif()

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
            IMPORTED_OBJECTS "${CMAKE_CURRENT_BINARY_DIR}/${assetsTargetDir}/${target}.o"
            ASSET_SOURCES "${sources}"
            ASSET_PREFIX "${ARGS_PREFIX}"
            ASSET_SUFFIX_START "${ARGS_SUFFIX_START}"
            ASSET_SUFFIX_END "${ARGS_SUFFIX_END}"
            ASSET_SUFFIX_SIZE "${ARGS_SUFFIX_SIZE}"
    )
    if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.27)
        target_sources(${target}
                INTERFACE "$<PATH:ABSOLUTE_PATH,NORMALIZE,$<TARGET_PROPERTY:${target},ASSET_SOURCES>,${CMAKE_CURRENT_SOURCE_DIR}>"
        )
    endif()
    target_include_directories(${target} INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/${assetsTargetDir}")
endfunction()
