cmake_minimum_required(VERSION 3.1)

project(maxmod ASM)

file(GLOB MAXMOD_SRC "source/*.s" "source_gba/*.s")

add_library(maxmod STATIC ${MAXMOD_SRC})
target_compile_definitions(maxmod PRIVATE SYS_GBA USE_IWRAM)
target_include_directories(maxmod SYSTEM PRIVATE "asm_include/")
target_include_directories(maxmod SYSTEM PUBLIC "include/")

set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -mthumb -x assembler-with-cpp")
