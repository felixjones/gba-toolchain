cmake_minimum_required(VERSION 3.1)

project(agbabi C ASM)

file(GLOB AGBABI_SRC "source/*.s" "source/*.c")

add_library(agbabi STATIC ${AGBABI_SRC})
target_include_directories(agbabi SYSTEM PUBLIC "include/")

set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -marm -x assembler-with-cpp")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -marm -Wall -fno-strict-aliasing")
