cmake_minimum_required(VERSION 3.8)
project(gbapp)

add_executable(${CMAKE_PROJECT_NAME} main.cpp)
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES SUFFIX ".elf")

target_compile_features(${CMAKE_PROJECT_NAME} PUBLIC cxx_std_20)

#====================
# ROM information
#====================

set(ROM_TITLE "GBA++")
set(ROM_GAME_CODE "CGPE")
set(ROM_MAKER_CODE "GT")
set(ROM_VERSION 100)

#====================
# GBA toolchain
#====================

if(GBA_TOOLCHAIN)
    gba_target_link_agb_abi(${CMAKE_PROJECT_NAME})
    gba_target_link_gba_plusplus(${CMAKE_PROJECT_NAME})

    gba_target_sources_instruction_set(${CMAKE_PROJECT_NAME} thumb)
    gba_target_link_runtime(${CMAKE_PROJECT_NAME} rom)
    gba_target_object_copy(${CMAKE_PROJECT_NAME} "${CMAKE_PROJECT_NAME}.elf" "${CMAKE_PROJECT_NAME}.gba")

    gba_target_fix(${CMAKE_PROJECT_NAME} "${CMAKE_PROJECT_NAME}.gba" "${ROM_TITLE}" "${ROM_GAME_CODE}" "${ROM_MAKER_CODE}" ${ROM_VERSION})
endif()
