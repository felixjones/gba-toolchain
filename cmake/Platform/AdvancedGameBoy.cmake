set(CMAKE_EXECUTABLE_FORMAT ELF CACHE INTERNAL "")
set(CMAKE_EXECUTABLE_SUFFIX .elf CACHE INTERNAL "")

function(install_rom target)
    if(NOT TARGET ${target})
        message(FATAL_ERROR "No target \"${target}\"")
        return()
    endif()

    #TODO: Parse args for DESTINATION

    add_custom_command(TARGET ${target} PRE_BUILD
        COMMAND "${CMAKE_COMMAND}"
        ARGS -D VERIFY=ON
            -D ROM_TITLE=$<TARGET_PROPERTY:${target},ROM_TITLE>
            -D ROM_ID=$<TARGET_PROPERTY:${target},ROM_ID>
            -D ROM_MAKER=$<TARGET_PROPERTY:${target},ROM_MAKER>
            -D ROM_VERSION=$<TARGET_PROPERTY:${target},ROM_VERSION>
            -P "${CMAKE_CURRENT_LIST_DIR}/cmake/GbaFix.cmake"
    )

    install(TARGETS ${target} DESTINATION ".")
    install(CODE "
        execute_process(
            COMMAND \"${CMAKE_OBJCOPY}\" -O binary \"$<TARGET_FILE_NAME:${target}>\" \"$<TARGET_FILE_BASE_NAME:${target}>.bin\"
            WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\"
        )

        set(CMAKE_OBJCOPY \"${CMAKE_OBJCOPY}\")
        include(${CMAKE_CURRENT_LIST_DIR}/cmake/GbaFix.cmake)
        gbafix(\"${CMAKE_INSTALL_PREFIX}/$<TARGET_FILE_BASE_NAME:${target}>.bin\"
            TITLE \"$<TARGET_PROPERTY:${target},ROM_TITLE>\"
            ID \"$<TARGET_PROPERTY:${target},ROM_ID>\"
            MAKER \"$<TARGET_PROPERTY:${target},ROM_MAKER>\"
            VERSION \"$<TARGET_PROPERTY:${target},ROM_VERSION>\"
            OUTPUT \"${CMAKE_INSTALL_PREFIX}/$<TARGET_FILE_BASE_NAME:${target}>.gba\"
        )
    ")
endfunction()
