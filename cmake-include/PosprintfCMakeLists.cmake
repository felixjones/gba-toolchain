cmake_minimum_required(VERSION 3.0)

project(posprintf ASM)

add_library(posprintf STATIC posprintf.S)
target_include_directories(posprintf SYSTEM PUBLIC "/include")

set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -marm -x assembler-with-cpp")
