cmake_minimum_required(VERSION 3.0)

project(rtc C)

add_library(rtc STATIC rtc.c)

gba_clang_minsizerel(CMAKE_C_FLAGS_MINSIZEREL)
set(CMAKE_BUILD_TYPE MinSizeRel)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -Wextra -Wno-unused-parameter")

target_include_directories(rtc SYSTEM PUBLIC "include/")
