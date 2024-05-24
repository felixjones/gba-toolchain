#===============================================================================
#
# Butano project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(14-butano-project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(butano REQUIRED)

file(GLOB_RECURSE dmg_audio CONFIGURE_DEPENDS dmg_audio/*.vgm dmg_audio/*.s3m)
add_butano_library(butano
        DMG_AUDIO ${dmg_audio}
)
target_link_libraries(butano INTERFACE butano-common)

file(GLOB sources CONFIGURE_DEPENDS src/*.cpp)
add_executable(14-butano ${sources})
target_include_directories(14-butano PRIVATE include)

# Set IWRAM compile options
get_target_property(iwramSources 14-butano SOURCES)
list(FILTER iwramSources INCLUDE REGEX ".+\\.bn_iwram\\..+")
set_source_files_properties(${iwramSources} PROPERTIES COMPILE_FLAGS "-fno-lto -marm -mlong-calls -O2 -gdwarf-4 -mcpu=arm7tdmi -mtune=arm7tdmi -ffunction-sections -fdata-sections")

target_link_libraries(14-butano PRIVATE
        librom butano
)

install_rom(14-butano)
