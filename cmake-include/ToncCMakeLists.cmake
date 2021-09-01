cmake_minimum_required(VERSION 3.0)

project(tonc C ASM)

file(GLOB TONC_SRC "asm/*.s" "src/*.c" "src/*.s" "src/font/*.s" "src/tte/*.c" "src/tte/*.s" "src/pre1.3/*.c" "src/pre1.3/*.s")

# Remove tt_iohook.c which isn't compatible right now
get_filename_component(TTE_IOHOOK "${CMAKE_CURRENT_SOURCE_DIR}/src/tte/tte_iohook.c" ABSOLUTE)
list(REMOVE_ITEM TONC_SRC "${TTE_IOHOOK}")

add_library(tonc STATIC ${TONC_SRC})
target_include_directories(tonc SYSTEM PUBLIC "include/")

set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -mthumb -x assembler-with-cpp")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -Wextra -Wno-unused-parameter -Wno-char-subscripts -Wno-sign-compare -Wno-implicit-fallthrough")
