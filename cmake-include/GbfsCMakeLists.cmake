cmake_minimum_required(VERSION 3.0)

if(GBA_TOOLCHAIN)
    # Project for GBA library
    project(libgbfs C)

    add_library(libgbfs STATIC "source/libgbfs.c")
    target_include_directories(libgbfs SYSTEM PUBLIC "include/")

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -fno-strict-aliasing -Wno-char-subscripts")
else()
    # Project for host tools
    project(gbfs C)

    add_executable(gbfs "tools/gbfs.c")

    add_executable(bin2s "tools/bin2s.c")

    add_executable(padbin "tools/padbin.c")
endif()
