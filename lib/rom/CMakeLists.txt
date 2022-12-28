cmake_minimum_required(VERSION 3.0)
project(rom ASM)

add_library(rom STATIC crt0.s)

# Detect nano
find_library(rom_NANO c_nano)

target_link_options(rom
    PRIVATE
        -Wl,--gc-sections
    INTERFACE
        -T "${CMAKE_CURRENT_LIST_DIR}/rom.ld"
        $<$<BOOL:${rom_NANO}>:-specs=nano.specs>
        -specs=nosys.specs
)

unset(rom_NANO CACHE)
