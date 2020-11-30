cmake_minimum_required(VERSION 3.1)

project(gbfs ASM)

add_library(gbfs STATIC "source/libgbfs.c")
target_include_directories(gbfs SYSTEM PUBLIC "include/")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -fno-strict-aliasing -Wno-char-subscripts")
