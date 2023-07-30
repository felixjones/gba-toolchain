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

set(GBAFIX_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/../GbaFix.cmake")
set(CONCAT_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/../Concat.cmake")

function(install_rom target)
    if(NOT TARGET ${target})
        message(FATAL_ERROR "No target \"${target}\"")
        return()
    endif()

    cmake_parse_arguments(ARGS "" "DESTINATION" "CONCAT" ${ARGN})
    if(NOT ARGS_DESTINATION)
        set(ARGS_DESTINATION ".")
    endif()

    add_custom_command(TARGET ${target} PRE_BUILD
        COMMAND "${CMAKE_COMMAND}"
        ARGS -D VERIFY=ON
            -D ROM_TITLE=$<TARGET_PROPERTY:${target},ROM_TITLE>
            -D ROM_ID=$<TARGET_PROPERTY:${target},ROM_ID>
            -D ROM_MAKER=$<TARGET_PROPERTY:${target},ROM_MAKER>
            -D ROM_VERSION=$<TARGET_PROPERTY:${target},ROM_VERSION>
            -P "${GBAFIX_SCRIPT}"
    )

    cmake_parse_arguments(CONCAT_ARGS "" "ALIGN" "" ${ARGS_CONCAT})

    if(NOT CONCAT_ARGS_ALIGN)
        set(CONCAT_ARGS_ALIGN 1)
    endif()

    foreach(concat ${CONCAT_ARGS_UNPARSED_ARGUMENTS})
        if(NOT TARGET ${concat})
            get_filename_component(concat "${concat}" ABSOLUTE)
            list(APPEND appendFiles ${concat})
        else()
            add_dependencies(${target} ${concat})
            list(APPEND appendFiles $<TARGET_GENEX_EVAL:${concat},$<TARGET_PROPERTY:${concat},TARGET_FILE>>)
        endif()
    endforeach()

    set(INSTALL_DESTINATION "${CMAKE_INSTALL_PREFIX}/${ARGS_DESTINATION}")
    install(TARGETS ${target} DESTINATION "${ARGS_DESTINATION}")
    install(CODE "
        execute_process(
            COMMAND \"${CMAKE_OBJCOPY}\" -O binary \"$<TARGET_FILE_NAME:${target}>\" \"$<TARGET_FILE_BASE_NAME:${target}>.bin\"
            WORKING_DIRECTORY \"${INSTALL_DESTINATION}\"
        )

        set(CMAKE_OBJCOPY \"${CMAKE_OBJCOPY}\")
        include(\"${GBAFIX_SCRIPT}\")
        gbafix(\"${INSTALL_DESTINATION}/$<TARGET_FILE_BASE_NAME:${target}>.bin\"
            TITLE \"$<TARGET_PROPERTY:${target},ROM_TITLE>\"
            ID \"$<TARGET_PROPERTY:${target},ROM_ID>\"
            MAKER \"$<TARGET_PROPERTY:${target},ROM_MAKER>\"
            VERSION \"$<TARGET_PROPERTY:${target},ROM_VERSION>\"
            OUTPUT \"${INSTALL_DESTINATION}/$<TARGET_FILE_BASE_NAME:${target}>.gba\"
        )

        set(appendFiles ${appendFiles})
        if(appendFiles)
            include(\"${CONCAT_SCRIPT}\")
            binconcat(${CONCAT_ARGS_ALIGN} \"${INSTALL_DESTINATION}/$<TARGET_FILE_BASE_NAME:${target}>.gba\" \${appendFiles})
        endif()
    ")
endfunction()

set(ASSET_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/../Asset.cmake")

function(add_asset_library target)
    cmake_parse_arguments(ARGS "" "PREFIX" "" ${ARGN})

    set(ASSETS $<TARGET_GENEX_EVAL:${target},$<TARGET_PROPERTY:${target},ASSETS>>)

    add_custom_command(
        OUTPUT ${target}.s
        COMMAND "${CMAKE_COMMAND}" -D PREFIX=${ARGS_PREFIX} "-DINPUTS=${ASSETS}" "-DOUTPUT=${CMAKE_BINARY_DIR}/${target}.s" -P "${ASSET_SCRIPT}"
        DEPENDS ${ASSETS}
        VERBATIM
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    )

    enable_language(ASM)
    add_library(${target} OBJECT ${target}.s)

    if(ARGS_UNPARSED_ARGUMENTS)
        set_target_properties(${target} PROPERTIES
            ASSETS "${ARGS_UNPARSED_ARGUMENTS}"
        )
    endif()
endfunction()
