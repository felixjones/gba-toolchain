cmake_minimum_required(VERSION 3.1)

project("GameBoyAdvance" ASM C CXX)
set(GameID "GAME")

set(DefaultInstructionSet	"thumb")

if(NOT CMAKE_BUILD_TYPE) 
    set(CMAKE_BUILD_TYPE Release)
endif(NOT CMAKE_BUILD_TYPE)

#====================
# Headers
#====================

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/source")

file(GLOB Headers
	"source/*.h"
	"source/*.hpp"
)

#====================
# Main Code
#====================

file(GLOB MainSources
	"source/*.s"
	"source/*.c"
	"source/*.cpp"
)
list(FILTER MainSources EXCLUDE REGEX "((\.ewram)|(\.iwram)|(\.arm)|(\.thumb))(\.s|\.c|\.cpp)")

if(MainSources)
	add_library(MainCode OBJECT ${Headers} ${MainSources})
	target_compile_options(MainCode PRIVATE "-m${DefaultInstructionSet}")
endif()

#====================
# thumb Code
#====================

file(GLOB thumbSources
	"source/*.thumb.s"
	"source/*.thumb.c"
	"source/*.thumb.cpp"
)

if(thumbSources)
	add_library(thumbCode OBJECT ${Headers} ${thumbSources})
	target_compile_options(thumbCode PRIVATE "-mthumb")
endif()

#====================
# ARM Code
#====================

file(GLOB armSources
	"source/*.arm.s"
	"source/*.arm.c"
	"source/*.arm.cpp"
)

if(armSources)
	add_library(ARMCode OBJECT ${Headers} ${armSources})
	target_compile_options(ARMCode PRIVATE "-marm")
endif()

#====================
# IWRAM Code
#====================

file(GLOB IWRAMSources
	"source/*.iwram.s"
	"source/*.iwram.c"
	"source/*.iwram.cpp"
)

if(IWRAMSources)
	add_library(IWRAMCode OBJECT ${Headers} ${IWRAMSources})
	target_compile_options(IWRAMCode PRIVATE "-marm" "-mlong-calls")
endif()

#====================
# EWRAM Code
#====================

file(GLOB EWRAMSources
	"source/*.ewram.s"
	"source/*.ewram.c"
	"source/*.ewram.cpp"
)

if(EWRAMSources)
	add_library(EWRAMCode OBJECT ${Headers} ${EWRAMSources})
	target_compile_options(EWRAMCode PRIVATE "-mthumb" "-mlong-calls")
endif()

#====================
# ROM & Multiboot
#====================

add_executable(rom.elf)
add_executable(multiboot.elf)

target_link_libraries(rom.elf PRIVATE -specs=${SpecsPath}rom/gba.specs)
target_link_libraries(multiboot.elf PRIVATE -specs=${SpecsPath}multiboot/gba.specs)

if(MainSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:MainCode>)
	target_sources(multiboot.elf PUBLIC $<TARGET_OBJECTS:MainCode>)
endif()

if(thumbSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:thumbCode>)
	target_sources(multiboot.elf PUBLIC $<TARGET_OBJECTS:thumbCode>)
endif()

if(ARMSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:ARMCode>)
	target_sources(multiboot.elf PUBLIC $<TARGET_OBJECTS:ARMCode>)
endif()

if(IWRAMSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:IWRAMCode>)
	target_sources(multiboot.elf PUBLIC $<TARGET_OBJECTS:IWRAMCode>)
endif()

if(EWRAMSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:EWRAMCode>)
	target_sources(multiboot.elf PUBLIC $<TARGET_OBJECTS:EWRAMCode>)
endif()

#====================
# GBA
#====================

if(HasGBAFix)
	add_custom_command(
		TARGET rom.elf
		POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -O binary rom.elf rom.gba
		COMMAND ${GBAFixROM}
		COMMENT "Building ROM and fixing header"
		BYPRODUCTS rom.gba
	)

	add_custom_command(
		TARGET multiboot.elf
		POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -O binary multiboot.elf multiboot.gba
		COMMAND ${GBAFixMultiboot}
		COMMENT "Building Multiboot and fixing header"
		BYPRODUCTS multiboot.gba
	)
else()
	add_custom_command(
		TARGET rom.elf
		POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -O binary rom.elf rom.gba
		COMMENT "Building ROM (header not fixed)"
		BYPRODUCTS rom.gba
	)

	add_custom_command(
		TARGET multiboot.elf
		POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -O binary multiboot.elf multiboot.gba
		COMMENT "Building Multiboot (header not fixed)"
		BYPRODUCTS multiboot.gba
	)
endif()
