enable_language(ASM)

add_library(librom STATIC crt0.s)
set_target_properties(librom PROPERTIES PREFIX "")

# Detect nano
find_library(librom_NANO c_nano)

target_link_options(librom
    PRIVATE
        -Wl,--gc-sections
    INTERFACE
        -T "${CMAKE_CURRENT_LIST_DIR}/rom.ld"
        $<$<BOOL:${rom_NANO}>:-specs=nano.specs>
        -specs=nosys.specs
)

unset(librom_NANO CACHE)
