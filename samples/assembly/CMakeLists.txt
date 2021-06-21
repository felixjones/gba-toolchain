cmake_minimum_required(VERSION 3.1)
project(assembly ASM)

add_executable(${CMAKE_PROJECT_NAME} main.s)
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES SUFFIX ".elf")

#====================
# ROM information
#====================

set(ROM_TITLE "Assembly")
set(ROM_GAME_CODE "CAYE")
set(ROM_MAKER_CODE "GT")
set(ROM_VERSION 100)

#====================
# GBA toolchain
#====================

if(GBA_TOOLCHAIN)
    gba_target_link_runtime(${CMAKE_PROJECT_NAME} rom)
    gba_target_object_copy(${CMAKE_PROJECT_NAME} "${CMAKE_PROJECT_NAME}.elf" "${CMAKE_PROJECT_NAME}.gba")

    gba_target_fix(${CMAKE_PROJECT_NAME} "${CMAKE_PROJECT_NAME}.gba" "${ROM_TITLE}" "${ROM_GAME_CODE}" "${ROM_MAKER_CODE}" ${ROM_VERSION})
endif()
