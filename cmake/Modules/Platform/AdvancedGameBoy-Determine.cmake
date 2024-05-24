#===============================================================================
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

function(__gba_check_compiler_armv4t result compilerPath)
    if(CMAKE_HOST_WIN32)
        set(input NUL)
    else()
        set(input /dev/null)
    endif()

    execute_process(
            COMMAND ${compilerPath} -dM -E -
            OUTPUT_VARIABLE compilerMacros
            INPUT_FILE ${input}
            ERROR_QUIET
    )

    if(compilerMacros MATCHES "__clang__") # Clang needs the cross compiled target to be specified
        execute_process(
                COMMAND ${compilerPath} --target=arm-none-eabi -dM -E -
                OUTPUT_VARIABLE compilerMacros
                INPUT_FILE ${input}
                ERROR_QUIET
        )
    endif()

    if(compilerMacros MATCHES "__ARM_ARCH_4T__ 1")
        set(${result} TRUE PARENT_SCOPE)
    else()
        set(${result} FALSE PARENT_SCOPE)
    endif()
endfunction()

function(__gba_find_compiler lang)
    if(lang STREQUAL C)
        set(compilerList arm-none-eabi-gcc arm-none-eabi-cc gcc cc clang)
    elseif(lang STREQUAL CXX)
        set(compilerList arm-none-eabi-g++ arm-none-eabi-c++ g++ c++ clang++)
    else()
        message(FATAL_ERROR "Unable to detect compiler for language \"${lang}\"")
    endif()

    # Find a compiler
    find_program(CMAKE_${lang}_COMPILER
            NAMES ${compilerList}
            HINTS "${armGnuToolchain}" ${devkitARM}
            PATH_SUFFIXES bin
            VALIDATOR __gba_check_compiler_armv4t
            DOC "${lang} compiler"
    )

    if(NOT CMAKE_${lang}_COMPILER)
        message(FATAL_ERROR "Unable to detect armv4t compiler for language \"${lang}\"")
    endif()
endfunction()

function(__gba_find_arm_gnu_toolchain outPath)
    if(CMAKE_HOST_SYSTEM_NAME MATCHES Windows)
        foreach(path "ProgramW6432" "ProgramFiles" "ProgramFiles(x86)")
            if(DEFINED ENV{${path}})
                file(TO_CMAKE_PATH $ENV{${path}} envProgramfiles)
                list(APPEND programfiles ${envProgramfiles})
                unset(envProgramfiles)
            endif()
        endforeach()

        if(DEFINED ENV{SystemDrive})
            foreach(path "Program Files" "Program Files (x86)")
                if(EXISTS "$ENV{SystemDrive}/${path}")
                    list(APPEND programfiles "$ENV{SystemDrive}/${path}")
                endif()
            endforeach()
        endif()

        if(programfiles)
            list(REMOVE_DUPLICATES programfiles)
            find_path(gnuArmToolchain "Arm GNU Toolchain arm-none-eabi" PATHS ${programfiles} NO_CACHE)
            unset(programfiles)
        endif()

        if(gnuArmToolchain)
            file(GLOB gnuArmToolchain "${gnuArmToolchain}/Arm GNU Toolchain arm-none-eabi/*")
        endif()
    elseif(CMAKE_HOST_SYSTEM_NAME MATCHES Darwin)
        find_path(gnuArmToolchain ArmGNUToolchain PATHS "/Applications" NO_CACHE)

        if(gnuArmToolchain)
            file(GLOB gnuArmToolchain "${gnuArmToolchain}/ArmGNUToolchain/*/arm-none-eabi")
        endif()
    endif()

    if(gnuArmToolchain)
        list(SORT gnuArmToolchain COMPARE NATURAL ORDER DESCENDING)
        list(GET gnuArmToolchain 0 gnuArmToolchain)
        set(${outPath} ${gnuArmToolchain} PARENT_SCOPE)
    else()
        unset(${outPath} PARENT_SCOPE)
    endif()
endfunction()

function(__gba_find_devkitarm outPaths)
    if(CMAKE_HOST_SYSTEM_NAME MATCHES Windows)
        # Assume /opt/ is a top-level drive letter
        execute_process(
                COMMAND cmd /c "wmic logicaldisk get caption"
                OUTPUT_VARIABLE drivesRaw
        )
        string(REGEX MATCHALL "[A-Z]:" drives ${drivesRaw})

        foreach(drive ${drives})
            string(REPLACE "/opt" "${drive}" devkitARM $ENV{DEVKITARM})
            if(EXISTS ${devkitARM})
                list(APPEND foundPaths "${devkitARM}")
            endif()

            string(REPLACE "/opt" "${drive}" devkitpro $ENV{DEVKITPRO})
            if(EXISTS "${devkitpro}/msys2/usr")
                list(APPEND foundPaths "${devkitpro}" "${devkitpro}/msys2/usr")
            endif()
        endforeach()

        set(${outPaths} ${foundPaths} PARENT_SCOPE)
    else()
        set(${outPaths} "$ENV{DEVKITARM}" "$ENV{DEVKITPRO}" PARENT_SCOPE)
    endif()
endfunction()

__gba_find_arm_gnu_toolchain(armGnuToolchain) # Arm GNU Toolchain
__gba_find_devkitarm(devkitARM) # devkitARM

foreach(lang C CXX)
    if(NOT CMAKE_${lang}_COMPILER)
        # Auto detect valid compiler
        __gba_find_compiler(${lang})
        if(NOT CMAKE_${lang}_COMPILER)
            message(FATAL_ERROR "Unable to find armv4t compiler for language \"${lang}\"")
        endif()
    else()
        # Compiler has been set in the cache with -D
        # Assume the user intended to do this, and error if it fails
        __gba_check_compiler_armv4t(armv4t "${CMAKE_${lang}_COMPILER}")
        if(NOT armv4t)
            message(FATAL_ERROR "Language \"${lang}\" is unable to compile armv4t with compiler \"${CMAKE_${lang}_COMPILER}\"")
        endif()
    endif()
endforeach()
