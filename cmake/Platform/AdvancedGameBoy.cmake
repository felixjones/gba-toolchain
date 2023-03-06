set(CMAKE_EXECUTABLE_FORMAT ELF CACHE INTERNAL "")
set(CMAKE_EXECUTABLE_SUFFIX .elf CACHE INTERNAL "")

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
            -P "${CMAKE_CURRENT_LIST_DIR}/cmake/GbaFix.cmake"
    )

    cmake_parse_arguments(CONCAT_ARGS "" "ALIGN" "" ${ARGS_CONCAT})

    if(NOT CONCAT_ARGS_ALIGN)
        set(CONCAT_ARGS_ALIGN 1)
    endif()

    foreach(concat ${CONCAT_ARGS_UNPARSED_ARGUMENTS})
        if(NOT TARGET ${concat})
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
        include(${CMAKE_CURRENT_LIST_DIR}/cmake/GbaFix.cmake)
        gbafix(\"${INSTALL_DESTINATION}/$<TARGET_FILE_BASE_NAME:${target}>.bin\"
            TITLE \"$<TARGET_PROPERTY:${target},ROM_TITLE>\"
            ID \"$<TARGET_PROPERTY:${target},ROM_ID>\"
            MAKER \"$<TARGET_PROPERTY:${target},ROM_MAKER>\"
            VERSION \"$<TARGET_PROPERTY:${target},ROM_VERSION>\"
            OUTPUT \"${INSTALL_DESTINATION}/$<TARGET_FILE_BASE_NAME:${target}>.gba\"
        )

        set(appendFiles ${appendFiles})
        if(appendFiles)
            include(${CMAKE_CURRENT_LIST_DIR}/cmake/Concat.cmake)
            binconcat(${CONCAT_ARGS_ALIGN} \"${INSTALL_DESTINATION}/$<TARGET_FILE_BASE_NAME:${target}>.gba\" \${appendFiles})
        endif()
    ")
endfunction()
