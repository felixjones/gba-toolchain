cmake_minimum_required(VERSION 3.1)

project(agbabi C ASM)

add_library(agbabi STATIC
    source/getcontext.s
    source/irq.s
    source/idiv.s
    source/makecontext.c
    source/memcpy.s
    source/memset.s
    source/setcontext.s
    source/swapcontext.s
    source/uidiv.s
)
target_include_directories(agbabi SYSTEM PUBLIC "include/")

set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -marm -x assembler-with-cpp")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -marm -Wall -fno-strict-aliasing")
