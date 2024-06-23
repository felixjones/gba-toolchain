#===============================================================================
#
# Multiboot project
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(13-Multiboot-project LANGUAGES C VERSION 1.0.0)

# Multiboot Client

find_package(libmultiboot REQUIRED)
find_package(libgba)

add_executable(13-Multiboot-client
        client.c
)

target_link_libraries(13-Multiboot-client PRIVATE
        libmultiboot libgba
)

# Multiboot Host

find_package(librom REQUIRED)
find_package(tonclib REQUIRED)
find_package(agbabi REQUIRED)

add_executable(13-Multiboot-host
        host.c
)

add_custom_command(TARGET 13-Multiboot-client POST_BUILD
        BYPRODUCTS "13-Multiboot-client.gba"
        COMMAND "${CMAKE_OBJCOPY}" -O binary "13-Multiboot-client.elf" "13-Multiboot-client.bin"
        COMMAND "${CMAKE_COMMAND}" -P "${GBAFIX_PATH}" -- "13-Multiboot-client.bin" "13-Multiboot-client.gba"
)
set_source_files_properties(13-Multiboot-client.gba PROPERTIES GENERATED TRUE)
add_asset_library(host-assets 13-Multiboot-client.gba)

target_link_libraries(13-Multiboot-host PRIVATE
        librom tonclib agbabi
        host-assets
)

install_rom(13-Multiboot-host)
