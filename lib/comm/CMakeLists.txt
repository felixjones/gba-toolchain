cmake_minimum_required(VERSION 3.0)

project(comm C)

add_library(comm STATIC comm.c)

if(GBA_TOOLCHAIN)
    gba_clang_minsizerel(CMAKE_C_FLAGS_MINSIZEREL)
    set(CMAKE_BUILD_TYPE MinSizeRel)
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -Wextra -Wno-unused-parameter")

target_include_directories(comm SYSTEM PUBLIC "include/")
