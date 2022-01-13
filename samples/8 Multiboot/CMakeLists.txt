#===============================================================================
#
# Sample Multiboot GBA project
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

project(sample-multiboot ASM C)

gba_add_library_subdirectory(rom multiboot tonc gbfs agbabi)
# Disable ROM compatibility. This removes code for copying ROM into EWRAM.
target_compile_definitions(multiboot PUBLIC __NO_ROM_COPY__)

# Add the Multiboot client executable
add_executable(multibootClient client.c)
set_target_properties(multibootClient PROPERTIES SUFFIX ".elf")

target_compile_options(multibootClient PRIVATE -mthumb -ffunction-sections -fdata-sections -Wall -Wextra)
target_link_options(multibootClient PRIVATE -Wl,--gc-sections)
target_link_libraries(multibootClient PRIVATE tonc)
gba_target_link_runtime_library(multibootClient multiboot)
gba_target_objcopy(multibootClient FIX_HEADER OUTPUT client_mb.bin) # objcopy to client_mb.bin

# Add a GBFS archive that uses the Multiboot multibootClient objcopy output as a source
gba_add_gbfs(payload GENERATE_ASM "$<TARGET_PROPERTY:multibootClient,OBJCOPY_OUTPUT>")
set_target_properties(payload PROPERTIES SUFFIX ".bin")

# payload depends on multibootClient
add_dependencies(payload multibootClient)

# Add the ROM hosting executable that uses the GBFS payload assembly output as a source
add_executable(multibootHost host.c "$<TARGET_PROPERTY:payload,ASM_OUTPUT>")
set_target_properties(multibootHost PROPERTIES SUFFIX ".elf")

target_compile_options(multibootHost PRIVATE -Wall -mthumb)
target_link_libraries(multibootHost PRIVATE tonc gbfs agbabi)
gba_target_link_runtime_library(multibootHost rom)
gba_target_objcopy(multibootHost FIX_HEADER)

# multibootHost depends on payload
add_dependencies(multibootHost payload)
