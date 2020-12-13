function(gba_find_compilers)
    cmake_minimum_required(VERSION 3.0)

    set(ARM_GNU_TOOLS "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain")

    #====================
    # Clang detection
    #====================

    if(${USE_CLANG})
        if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
            find_program(CLANG_C_COMPILER NAMES "clang.exe")
            find_program(CLANG_CXX_COMPILER NAMES "clang++.exe")
        else()
            find_program(CLANG_C_COMPILER NAMES "clang")
            find_program(CLANG_CXX_COMPILER NAMES "clang++")
        endif()

        if(NOT (DEFINED CLANG_C_COMPILER AND DEFINED CLANG_CXX_COMPILER))
            message(FATAL_ERROR "Could not find Clang (USE_CLANG is ${USE_CLANG})")
        endif()
    endif()

    if(DEFINED CLANG_C_COMPILER AND DEFINED CLANG_CXX_COMPILER)
        if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
            find_program(GNU_C_COMPILER NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc.exe")
            find_program(GNU_CXX_COMPILER NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-g++.exe")
        else()
            find_program(GNU_C_COMPILER NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc")
            find_program(GNU_CXX_COMPILER NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-g++")
        endif()

        include_directories(SYSTEM
            ${ARM_GNU_TOOLS}/lib/gcc/arm-none-eabi/9.3.1/include
            ${ARM_GNU_TOOLS}/arm-none-eabi/include/c++/9.3.1
            ${ARM_GNU_TOOLS}/arm-none-eabi/include/c++/9.3.1/arm-none-eabi
        )

        set(CMAKE_C_FLAGS "-g --target=arm-arm-none-eabi ${CMAKE_C_FLAGS} ${C_HEADERS} -isystem \"${ARM_GNU_TOOLS}/arm-none-eabi/include\"" PARENT_SCOPE)
        set(CMAKE_CXX_FLAGS "-g --target=arm-arm-none-eabi ${CMAKE_CXX_FLAGS} ${CXX_HEADERS} -isystem \"${ARM_GNU_TOOLS}/arm-none-eabi/include\"" PARENT_SCOPE)

        set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -Xlinker -no-enum-size-warning" PARENT_SCOPE)
        set(CMAKE_CXX_LINK_FLAGS "${CMAKE_CXX_LINK_FLAGS} -Xlinker -no-enum-size-warning" PARENT_SCOPE)

        set(CMAKE_C_COMPILER "${CLANG_C_COMPILER}" PARENT_SCOPE)
        set(CMAKE_CXX_COMPILER "${CLANG_CXX_COMPILER}" PARENT_SCOPE)

        set(CMAKE_C_LINK_EXECUTABLE "\"${GNU_C_COMPILER}\" -g <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>" PARENT_SCOPE)
        set(CMAKE_CXX_LINK_EXECUTABLE "\"${GNU_CXX_COMPILER}\" -g <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>" PARENT_SCOPE)
    else()
        if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
            set(CMAKE_C_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc.exe" PARENT_SCOPE)
            set(CMAKE_CXX_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-g++.exe" PARENT_SCOPE)
        else()
            set(CMAKE_C_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc" PARENT_SCOPE)
            set(CMAKE_CXX_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-g++" PARENT_SCOPE)
        endif()
    endif()

    #====================
    # objcopy
    #====================

    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
        find_program(GNU_OBJCOPY NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-objcopy.exe")
    else()
        find_program(GNU_OBJCOPY NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-objcopy")
    endif()
    set(CMAKE_OBJCOPY "${GNU_OBJCOPY}" PARENT_SCOPE)

    #====================
    # ASM
    #====================

    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
        set(CMAKE_ASM_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc.exe" PARENT_SCOPE)
    else()
        set(CMAKE_ASM_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc" PARENT_SCOPE)
    endif()
    unset(CMAKE_ASM_FLAGS PARENT_SCOPE)

endfunction()
