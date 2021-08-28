cmake_minimum_required(VERSION 3.0)
project(multiboot ASM C)

add_executable(sender main.c)
set_target_properties(sender PROPERTIES SUFFIX ".elf")

#====================
# ROM information
#====================

set(ROM_TITLE "sender")
set(ROM_GAME_CODE "CSNE")
set(ROM_MAKER_CODE "GT")
set(ROM_VERSION 100)

#====================
# GBA toolchain
#====================

if(GBA_TOOLCHAIN)
    #====================
    # Add payload project
    #====================

    gba_external_project_add(payload
        SOURCE_DIR "${CMAKE_SOURCE_DIR}/payload"
        BINARY_DIR "${CMAKE_BINARY_DIR}/payload"
        INSTALL_COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_BINARY_DIR}/payload/payload.mb" "${CMAKE_BINARY_DIR}"
        CMAKE_CACHE_ARGS
        -DUSE_CLANG:BOOL=${USE_CLANG}
        CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    )
    add_dependencies(sender payload)

    #====================
    # Add GBFS assets
    #====================

    gba_add_gbfs_target(assets.gbfs "${CMAKE_BINARY_DIR}/payload.mb")
    add_dependencies(assets.gbfs payload)
    gba_target_add_gbfs_dependency(sender assets.gbfs)

    #====================
    # Configure sender
    #====================

    gba_target_link_tonc(sender)
    gba_target_link_posprintf(sender)
    gba_target_link_comm(sender)
    gba_target_link_gbfs(sender)

    gba_target_sources_instruction_set(sender thumb)
    gba_target_link_runtime(sender rom)
    gba_target_object_copy(sender "sender.elf" "sender.gba")

    gba_target_fix(sender "sender.gba" "${ROM_TITLE}" "${ROM_GAME_CODE}" "${ROM_MAKER_CODE}" ${ROM_VERSION})
endif()
