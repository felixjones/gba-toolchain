set(CMAKE_EXECUTABLE_FORMAT ELF CACHE INTERNAL "")
set(CMAKE_EXECUTABLE_SUFFIX .elf CACHE INTERNAL "")

function(install_rom target)
    if(NOT TARGET ${target})
        message(FATAL_ERROR "No target \"${target}\"")
        return()
    endif()

    #TODO: Parse args for DESTINATION

    unset(CMAKE_INSTALL_BINDIR)
    install(TARGETS ${target} DESTINATION ".")
    install(CODE "
        execute_process(
            COMMAND \"${CMAKE_OBJCOPY}\" -O binary \"$<TARGET_FILE_NAME:${target}>\" \"$<TARGET_FILE_BASE_NAME:${target}>.bin\"
            WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\"
        )
    ")
    #TODO: gbafix
endfunction()
