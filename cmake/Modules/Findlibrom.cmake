#===============================================================================
#
# GBA ROM runtime library
#   Provides both the runtime library, and the `install_rom` command to perform the "gbafix" operation
#
# Install GBA ROM command:
#   `install_rom(<target> [CONCAT [ALIGN <byte-alignment>] <artifact>...])`
#
#   `artifact` can be a target, a file path, or an output object.
# `install_rom` also uses target-properties:
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

add_subdirectory("${CMAKE_SYSTEM_PREFIX_PATH}/lib/rom" "${CMAKE_CURRENT_BINARY_DIR}/lib/rom" EXCLUDE_FROM_ALL)

include(GbaFix)
include(Mktemp)
include(Bincat)

function(install_rom target)
    if(NOT TARGET ${target})
        message(FATAL_ERROR "No target \"${target}\"")
        return()
    endif()

    cmake_parse_arguments(ARGS "" "" "CONCAT" ${ARGN})

    # Get gbafix parameters
    macro(get_gbafix_parameters list)
        foreach(property TITLE ID MAKER VERSION)
            get_target_property(var ${target} ROM_${property})
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

    # Install the .elf
    install(TARGETS ${target})

    # objcopy and gbafix
    set(installDir "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}")
    install(CODE "
        execute_process(
            COMMAND \"${CMAKE_OBJCOPY}\" -O binary \"$<TARGET_FILE_NAME:${target}>\" \"$<TARGET_FILE_BASE_NAME:${target}>.bin\"
            COMMAND \"${CMAKE_COMMAND}\" -P \"${GBAFIX_PATH}\" -- \"$<TARGET_FILE_BASE_NAME:${target}>.bin\" \"${params}\" \"$<TARGET_FILE_BASE_NAME:${target}>.gba\"
            WORKING_DIRECTORY \"${installDir}\"
        )
    ")

    if(NOT ARGS_CONCAT)
        return()
    endif()

    cmake_parse_arguments(CONCAT_ARGS "" "ALIGN" "" ${ARGS_CONCAT})

    if(NOT CONCAT_ARGS_ALIGN)
        set(CONCAT_ARGS_ALIGN 1)
    endif()

    # List files to be appended
    foreach(concat ${CONCAT_ARGS_UNPARSED_ARGUMENTS})
        if(NOT TARGET ${concat})
            list(APPEND appendFiles $<PATH:ABSOLUTE_PATH,NORMALIZE,${concat},${CMAKE_CURRENT_SOURCE_DIR}>)
        else()
            add_dependencies(${target} ${concat})
            list(APPEND appendFiles $<TARGET_FILE:${concat}>)
        endif()
    endforeach()

    # Append files
    install(CODE "
        execute_process(
            COMMAND \"${CMAKE_COMMAND}\" -P \"${MKTEMP_PATH}\"
            OUTPUT_VARIABLE tmpfile OUTPUT_STRIP_TRAILING_WHITESPACE
            WORKING_DIRECTORY \"${installDir}\"
        )

        execute_process(
            COMMAND \"${CMAKE_COMMAND}\" -P \"${BINCAT_PATH}\" --
                \"\${tmpfile}\"
                BOUNDARY ${CONCAT_ARGS_ALIGN}
                \"$<TARGET_FILE_BASE_NAME:${target}>.gba\" ${appendFiles}
            WORKING_DIRECTORY \"${installDir}\"
        )

        file(REMOVE \"${installDir}/$<TARGET_FILE_BASE_NAME:${target}>.gba\")
        file(RENAME \"${installDir}/\${tmpfile}\" \"${installDir}/$<TARGET_FILE_BASE_NAME:${target}>.gba\")
    ")
endfunction()
