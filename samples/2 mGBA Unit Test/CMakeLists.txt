#===============================================================================
#
# Sample GBA unit test using mGBA
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

enable_testing()
project(mGBA-unit-test C)

gba_add_library_subdirectory(rom tonc)

add_executable(exampleProgram main.c)
set_target_properties(exampleProgram PROPERTIES SUFFIX ".elf")

target_compile_options(exampleProgram PRIVATE -mthumb -mcpu=arm7tdmi -Wall)
gba_target_sources_compile_options(exampleProgram IWRAM -g0 -Os -marm)

target_link_libraries(exampleProgram PRIVATE tonc)
gba_target_link_runtime_library(exampleProgram rom)

# Save files can be used to control the test being ran on mGBA
file(WRITE "${CMAKE_BINARY_DIR}/test-div.sav" "bios_div")

# Create a GBA test named "exampleTest" that checks for the output "BIOS div is 3"
gba_target_add_test(exampleProgram exampleTest
    TIMEOUT 2 # In seconds. Timeout is required to run the test until desired output is given
    SAVE_FILE "${CMAKE_BINARY_DIR}/test-div.sav" # This is copied (and renamed) into the Testing directory
    PASS_REGULAR_EXPRESSION "BIOS div is 3"
    FAIL_REGULAR_EXPRESSION "\\[FATAL\\]|\\[ERROR\\]"
)
