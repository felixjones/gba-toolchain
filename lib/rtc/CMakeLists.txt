cmake_minimum_required(VERSION 3.0)

project(rtc C)

add_library(rtc STATIC rtc.c)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -Wextra -Wno-unused-parameter")

target_include_directories(rtc SYSTEM PUBLIC "include/")
