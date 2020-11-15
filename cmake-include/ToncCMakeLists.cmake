cmake_minimum_required(VERSION 3.1)

project(tonc C ASM)

file(GLOB TONC_SRC "asm/*.s" "src/*.c" "src/*.s")

add_library(tonc STATIC ${TONC_SRC})
target_include_directories(tonc SYSTEM PUBLIC "include/")

set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -mthumb -x assembler-with-cpp")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -fno-strict-aliasing -mthumb")
