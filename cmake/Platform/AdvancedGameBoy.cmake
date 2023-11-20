#===============================================================================
#
# Provides the CMake function `install_rom` for installing a GBA .elf archive into a .gba ROM file
#
#   The GBA header is configured with the `ROM_TITLE`, `ROM_ID`, `ROM_MAKER`, and `ROM_VERSION` target properties
#   The optional `CONCAT` parameter allows for concatenating binary data to the .gba file
#   When using `CONCAT`, the optional `ALIGN` parameter sets a byte alignment for the concatenated binary data
#
#   Example:
#   ```cmake
#   set_target_properties(my_executable PROPERTIES
#       ROM_TITLE "My Title"
#       ROM_ID AXYE
#       ROM_MAKER ZW
#       ROM_VERSION 1
#   )
#   install_rom(my_executable CONCAT ALIGN 0x100
#       binary_file.bin
#       another_binary_file.bin
#       $<TARGET_PROPERTY:my_gbfs_target,GBFS_FILE>
#   )
#   ```
#
# Provides the CMake function `add_asset_library` for archiving assets files to a `.s` assembly file
#
#   asset library targets convert the input files into a `.s` assembly file, available by linking with the target
#
#   Example:
#   ```cmake
#   add_asset_library(my_assets
#       path/to/my/file.bin
#       path/to/another/file.txt
#       $<TARGET_PROPERTY:my_superfamiconv_target,OUTPUT_FILES>
#   )
#   target_link_libraries(my_executable PRIVATE my_assets)
#   ```
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

foreach(suffix "" _ASM _C _CXX)
    set(CMAKE_EXECUTABLE_FORMAT${suffix} ELF CACHE INTERNAL "")
    set(CMAKE_EXECUTABLE_SUFFIX${suffix} .elf CACHE INTERNAL "")
endforeach()

# Setup default install prefix
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}" CACHE PATH "Installation prefix path for the project install step" FORCE)
endif()

include(GbaFix)
include(Mktemp)
include(Bincat)

function(install_rom target)
    if(NOT TARGET ${target})
        message(FATAL_ERROR "No target \"${target}\"")
        return()
    endif()

    cmake_parse_arguments(ARGS "" "DESTINATION" "CONCAT" ${ARGN})
    if(NOT ARGS_DESTINATION)
        set(ARGS_DESTINATION ".")
    endif()

    # Add gbafix checking command
    add_custom_command(TARGET ${target} PRE_BUILD
        COMMAND "${CMAKE_COMMAND}" -P "${GBAFIX_SCRIPT}" -- $<TARGET_FILE_NAME:${target}> DRY_RUN
            TITLE $<TARGET_PROPERTY:${target},ROM_TITLE>
            ID $<TARGET_PROPERTY:${target},ROM_ID>
            MAKER $<TARGET_PROPERTY:${target},ROM_MAKER>
            VERSION $<TARGET_PROPERTY:${target},ROM_VERSION>
    )

    set(INSTALL_DESTINATION "${CMAKE_INSTALL_PREFIX}/${ARGS_DESTINATION}")

    # Install the .elf
    install(TARGETS ${target} DESTINATION "${ARGS_DESTINATION}")

    # objcopy and gbafix
    install(CODE "
        execute_process(
            COMMAND \"${CMAKE_OBJCOPY}\" -O binary \"$<TARGET_FILE_NAME:${target}>\" \"$<TARGET_FILE_BASE_NAME:${target}>.bin\"
            COMMAND \"${CMAKE_COMMAND}\" -P \"${GBAFIX_SCRIPT}\" -- \"$<TARGET_FILE_BASE_NAME:${target}>.bin\"
                \"$<TARGET_FILE_BASE_NAME:${target}>.gba\"
                TITLE \"$<TARGET_PROPERTY:${target},ROM_TITLE>\"
                ID \"$<TARGET_PROPERTY:${target},ROM_ID>\"
                MAKER \"$<TARGET_PROPERTY:${target},ROM_MAKER>\"
                VERSION \"$<TARGET_PROPERTY:${target},ROM_VERSION>\"
            WORKING_DIRECTORY \"${INSTALL_DESTINATION}\"
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
            get_filename_component(concat "${concat}" ABSOLUTE)
            list(APPEND appendFiles ${concat})
        else()
            add_dependencies(${target} ${concat})
            list(APPEND appendFiles $<TARGET_GENEX_EVAL:${concat},$<TARGET_PROPERTY:${concat},TARGET_FILE>>)
        endif()
    endforeach()

    # Append files
    install(CODE "
        execute_process(
            COMMAND \"${CMAKE_COMMAND}\" -P \"${MKTEMP_SCRIPT}\"
            OUTPUT_VARIABLE tmpfile OUTPUT_STRIP_TRAILING_WHITESPACE
            WORKING_DIRECTORY \"${INSTALL_DESTINATION}\"
        )

        execute_process(
            COMMAND \"${CMAKE_COMMAND}\" -P \"${BINCAT_SCRIPT}\" --
                \"$<TARGET_FILE_BASE_NAME:${target}>.gba\"
                \"\${tmpfile}\"
                ${CONCAT_ARGS_ALIGN}
                ${appendFiles}
            WORKING_DIRECTORY \"${INSTALL_DESTINATION}\"
        )

        file(REMOVE \"${INSTALL_DESTINATION}/$<TARGET_FILE_BASE_NAME:${target}>.gba\")
        file(RENAME \"${INSTALL_DESTINATION}/\${tmpfile}\" \"${INSTALL_DESTINATION}/$<TARGET_FILE_BASE_NAME:${target}>.gba\")
    ")
endfunction()

find_program(CMAKE_BIN2S_PROGRAM bin2s bin2s.exe PATHS "$ENV{DEVKITPRO}/tools" "${CMAKE_SYSTEM_LIBRARY_PATH}/gbfs" "${GBFS_DIR}" PATH_SUFFIXES bin)
include(Bin2s)

function(add_asset_library target)
    set(assetsEval $<TARGET_GENEX_EVAL:${target},$<TARGET_PROPERTY:${target},ASSETS>>)

    if(CMAKE_BIN2S_PROGRAM)
        add_custom_command(
            OUTPUT ${target}.s
            COMMAND "${CMAKE_BIN2S_PROGRAM}" "${assetsEval}" > "${CMAKE_BINARY_DIR}/${target}.s"
            DEPENDS ${assetsEval}
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        )
    else()
        add_custom_command(
            OUTPUT ${target}.s
            COMMAND "${CMAKE_COMMAND}" -P "${BIN2S_SCRIPT}" -- "${assetsEval}" > "${CMAKE_BINARY_DIR}/${target}.s"
            DEPENDS ${assetsEval}
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        )
    endif()

    add_library(${target} OBJECT ${target}.s)

    set_target_properties(${target} PROPERTIES
        ASSETS "${ARGN}"
    )
endfunction()
