#===============================================================================
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

if(__GBA_COMMON)
    return()
endif()
set(__GBA_COMMON 1)

set(CMAKE_SIZEOF_VOID_P ON) # Required for GNUInstallDirs
include(GNUInstallDirs REQUIRED) # Sets the install bin/lib/include paths
unset(CMAKE_SIZEOF_VOID_P) # Restore (to allow normal language detection)

# Disable linking for compiler tests
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Default linker flags
string(APPEND CMAKE_EXE_LINKER_FLAGS_INIT " -mthumb -Wl,-n -Wl,--gc-sections -Wl,--no-warn-rwx-segments -Wl,-Map=% -nostartfiles")

# Detect the presence of libnano
execute_process(
        COMMAND "${CMAKE_C_COMPILER}" -print-search-dirs
        OUTPUT_VARIABLE newlibNano
)
string(REGEX MATCH "libraries:[ \t]=*([^\r\n]*)" newlibNano "${newlibNano}" )
unset(newlibNano)
find_library(newlibNano
        NAMES c_nano g_nano stdc++_nano supc++_nano
        PATHS ${CMAKE_MATCH_1}
)
if(newlibNano)
    set(NEWLIB_NANO 1)
endif()

# Detect the presence of picolibc
execute_process(
        COMMAND "${CMAKE_C_COMPILER}" -print-search-dirs
        OUTPUT_VARIABLE picolibc
)
string(REGEX MATCH "libraries:[ \t]=*([^\r\n]*)" picolibc "${picolibc}" )
unset(picolibc)
if(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
    string(REPLACE ":" ";" CMAKE_MATCH_1 "${CMAKE_MATCH_1}")
endif()
find_file(picolibc
        NAMES picolibc.specs
        PATHS ${CMAKE_MATCH_1}
)
if(picolibc)
    set(PICOLIBC 1)
endif()

macro(__gba_compiler_common lang)
    # Default compiler flags
    set(CMAKE_${lang}_FLAGS_INIT " -ffunction-sections -fdata-sections -mthumb -D__GBA__")
    set(CMAKE_${lang}_FLAGS_DEBUG_INIT " -O0 -g3 -gdwarf-4 -D_DEBUG")
    set(CMAKE_${lang}_FLAGS_RELEASE_INIT " -O3 -DNDEBUG")
    set(CMAKE_${lang}_FLAGS_MINSIZEREL_INIT " -Os -DNDEBUG")
    set(CMAKE_${lang}_FLAGS_RELWITHDEBINFO_INIT " -Og -g3 -gdwarf-4 -DNDEBUG")
endmacro()

if(CMAKE_VERSION VERSION_LESS 3.27.0)
    unset(_CMAKE_APPLE_ARCHS_DEFAULT)  # Workaround https://gitlab.kitware.com/cmake/cmake/-/issues/24599
endif()
