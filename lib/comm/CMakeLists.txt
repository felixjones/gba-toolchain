cmake_minimum_required(VERSION 3.0)

project(comm C)

add_library(comm STATIC comm_multiboot.c)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -Wextra -Wno-unused-parameter")

target_include_directories(comm SYSTEM PUBLIC "include/")
