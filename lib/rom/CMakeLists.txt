enable_language(ASM)

add_library(librom STATIC
    crt0.s
    rom.header.s
)
set_target_properties(librom PROPERTIES PREFIX "")

target_link_options(librom
    PRIVATE
        -Wl,--gc-sections
    INTERFACE
        -T "${CMAKE_CURRENT_LIST_DIR}/rom.ld"
        $<$<BOOL:${CMAKE_NANO}>:-specs=nano.specs>
        -specs=nosys.specs
)

execute_process(COMMAND "${CMAKE_C_COMPILER}" --version OUTPUT_VARIABLE GNU_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT GNU_VERSION MATCHES "devkitARM")
    enable_language(C)
    target_sources(librom PRIVATE syscalls.c)
endif()
