include("${CMAKE_CURRENT_LIST_DIR}/Detail.cmake")

function(gba_find_compilers)
    cmake_minimum_required(VERSION 3.0)

    set(ARM_GNU_TOOLS "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain")

    #====================
    # Clang detection
    #====================

    if(${USE_CLANG})
        if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows OR CMAKE_HOST_SYSTEM_NAME MATCHES "MING.*" OR CMAKE_HOST_SYSTEM_NAME MATCHES "MSYS.*")
            find_program(CLANG_C_COMPILER NAMES "clang.exe")
            find_program(CLANG_CXX_COMPILER NAMES "clang++.exe")
        else()
            find_program(CLANG_C_COMPILER NAMES "clang")
            find_program(CLANG_CXX_COMPILER NAMES "clang++")
        endif()

        if(NOT CLANG_C_COMPILER OR NOT CLANG_CXX_COMPILER)
            message(FATAL_ERROR "Could not find Clang (USE_CLANG is ${USE_CLANG})")
        endif()
    endif()

    if(CLANG_C_COMPILER AND CLANG_CXX_COMPILER)
        if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows OR CMAKE_HOST_SYSTEM_NAME MATCHES "MING.*" OR CMAKE_HOST_SYSTEM_NAME MATCHES "MSYS.*")
            find_program(GNU_C_COMPILER NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc.exe")
            find_program(GNU_CXX_COMPILER NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-g++.exe")
        else()
            find_program(GNU_C_COMPILER NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc")
            find_program(GNU_CXX_COMPILER NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-g++")
        endif()

        gba_list_directories("${ARM_GNU_TOOLS}/lib/gcc/arm-none-eabi/")
        set(gccVersion 0.0.0)
        foreach(version ${GBA_LIST_DIRECTORIES_OUT})
            if(${version} VERSION_GREATER ${gccVersion})
                set(gccVersion ${version})
            endif()
        endforeach()
        message(STATUS "Found arm-gnu-toolchain GCC ${gccVersion}")

        include_directories(SYSTEM
            ${ARM_GNU_TOOLS}/lib/gcc/arm-none-eabi/${gccVersion}/include
            ${ARM_GNU_TOOLS}/arm-none-eabi/include/c++/${gccVersion}
            ${ARM_GNU_TOOLS}/arm-none-eabi/include/c++/${gccVersion}/arm-none-eabi
        )

        set(CMAKE_C_FLAGS "--target=arm-arm-none-eabi -mabi=aapcs -march=armv4t -mcpu=arm7tdmi -isystem \"${ARM_GNU_TOOLS}/arm-none-eabi/include\"" PARENT_SCOPE)
        set(CMAKE_CXX_FLAGS "--target=arm-arm-none-eabi -mabi=aapcs -march=armv4t -mcpu=arm7tdmi -isystem \"${ARM_GNU_TOOLS}/arm-none-eabi/include\"" PARENT_SCOPE)

        set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -Xlinker -no-enum-size-warning" PARENT_SCOPE)
        set(CMAKE_CXX_LINK_FLAGS "${CMAKE_CXX_LINK_FLAGS} -Xlinker -no-enum-size-warning" PARENT_SCOPE)

        set(CMAKE_C_COMPILER "${CLANG_C_COMPILER}" PARENT_SCOPE)
        set(CMAKE_CXX_COMPILER "${CLANG_CXX_COMPILER}" PARENT_SCOPE)

        set(CMAKE_C_LINK_EXECUTABLE "\"${GNU_C_COMPILER}\" <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>" PARENT_SCOPE)
        set(CMAKE_CXX_LINK_EXECUTABLE "\"${GNU_CXX_COMPILER}\" <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>" PARENT_SCOPE)
    else()
        set(CMAKE_C_FLAGS "-mabi=aapcs -march=armv4t -mcpu=arm7tdmi" PARENT_SCOPE)
        set(CMAKE_CXX_FLAGS "-mabi=aapcs -march=armv4t -mcpu=arm7tdmi" PARENT_SCOPE)

        if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows OR CMAKE_HOST_SYSTEM_NAME MATCHES "MING.*" OR CMAKE_HOST_SYSTEM_NAME MATCHES "MSYS.*")
            set(CMAKE_C_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc.exe" PARENT_SCOPE)
            set(CMAKE_CXX_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-g++.exe" PARENT_SCOPE)
        else()
            set(CMAKE_C_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc" PARENT_SCOPE)
            set(CMAKE_CXX_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-g++" PARENT_SCOPE)
        endif()
    endif()

    #====================
    # objcopy ar ranlib nm objdump strip
    #====================

    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows OR CMAKE_HOST_SYSTEM_NAME MATCHES "MING.*" OR CMAKE_HOST_SYSTEM_NAME MATCHES "MSYS.*")
        find_program(GNU_OBJCOPY NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-objcopy.exe")
        find_program(GNU_AR NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-ar.exe")
        find_program(GNU_RANLIB NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-ranlib.exe")
        find_program(GNU_NM NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-nm.exe")
        find_program(GNU_OBJDUMP NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-objdump.exe")
        find_program(GNU_STRIP NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-strip.exe")
    else()
        find_program(GNU_OBJCOPY NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-objcopy")
        find_program(GNU_AR NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-ar")
        find_program(GNU_RANLIB NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-ranlib")
        find_program(GNU_NM NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-nm")
        find_program(GNU_OBJDUMP NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-objdump")
        find_program(GNU_STRIP NAMES "${ARM_GNU_TOOLS}/bin/arm-none-eabi-strip")
    endif()

    set(CMAKE_OBJCOPY "${GNU_OBJCOPY}" CACHE FILEPATH "objcopy")
    set(CMAKE_AR "${GNU_AR}" CACHE FILEPATH "ar")
    set(CMAKE_RANLIB "${GNU_RANLIB}" CACHE FILEPATH "ranlib")
    set(CMAKE_NM "${GNU_NM}" CACHE FILEPATH "nm")
    set(CMAKE_OBJDUMP "${GNU_OBJDUMP}" CACHE FILEPATH "objdump")
    set(CMAKE_STRIP "${GNU_STRIP}" CACHE FILEPATH "strip")

    #====================
    # Linkers
    #====================

    set(CMAKE_LINKER "${GNU_C_COMPILER}" CACHE FILEPATH "ld")
    set(CMAKE_SHARED_LINKER "${GNU_C_COMPILER}" CACHE FILEPATH "shared ld")
    set(CMAKE_STATIC_LINKER "${GNU_C_COMPILER}" CACHE FILEPATH "static ld")

    #====================
    # Archivers
    #====================

    set(CMAKE_C_COMPILER_AR "${CMAKE_AR}" CACHE FILEPATH "c ar")
    set(CMAKE_C_COMPILER_RANLIB "${CMAKE_RANLIB}" CACHE FILEPATH "c ranlib")

    set(CMAKE_CXX_COMPILER_AR "${CMAKE_AR}" CACHE FILEPATH "c++ ar")
    set(CMAKE_CXX_COMPILER_RANLIB "${CMAKE_RANLIB}" CACHE FILEPATH "c++ ranlib")

    #====================
    # ASM
    #====================

    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows OR CMAKE_HOST_SYSTEM_NAME MATCHES "MING.*" OR CMAKE_HOST_SYSTEM_NAME MATCHES "MSYS.*")
        set(CMAKE_ASM_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc.exe" PARENT_SCOPE)
    else()
        set(CMAKE_ASM_COMPILER "${ARM_GNU_TOOLS}/bin/arm-none-eabi-gcc" PARENT_SCOPE)
    endif()
    set(CMAKE_ASM_FLAGS "-mabi=aapcs -march=armv4t -mcpu=arm7tdmi" PARENT_SCOPE)

endfunction()

function(gba_clang_minsizerel inOutFlags)
    if(${USE_CLANG})
        string(REPLACE "-Os" "-Oz" newFlags ${${inOutFlags}})
        set(${inOutFlags} ${newFlags} PARENT_SCOPE)
    endif()
endfunction()
