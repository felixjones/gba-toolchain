#===============================================================================
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

enable_language(ASM C CXX)

include(FetchContent)

find_file(butano NAMES butano/butano.mak PATHS "$ENV{DEVKITPRO}/butano" "${CMAKE_SYSTEM_LIBRARY_PATH}/butano" "${BUTANO_DIR}" PATH_SUFFIXES source NO_CACHE)

if(NOT butano)
    set(SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/butano")

    file(MAKE_DIRECTORY "${SOURCE_DIR}/temp")
    FetchContent_Declare(butano_proj DOWNLOAD_EXTRACT_TIMESTAMP ON
        PREFIX "${SOURCE_DIR}"
        TMP_DIR "${SOURCE_DIR}/temp"
        STAMP_DIR "${SOURCE_DIR}/stamp"
        SOURCE_DIR "${SOURCE_DIR}/source"
        # Download
        DOWNLOAD_DIR "${SOURCE_DIR}/download"
        GIT_REPOSITORY "https://github.com/GValiente/butano.git"
        GIT_TAG "master"
    )

    FetchContent_Populate(butano_proj)
    set(butano "${butano_proj_SOURCE_DIR}")
else()
    get_filename_component(butano "${butano}" DIRECTORY)
    get_filename_component(butano "${butano}" DIRECTORY)
endif()
file(RELATIVE_PATH butano "${CMAKE_SOURCE_DIR}" "${butano}")

# Butano is treated as an OBJECT library
file(GLOB src "${butano}/butano/src/*.cpp")
file(GLOB hw_src "${butano}/butano/hw/src/*.cpp")
file(GLOB hw_asm "${butano}/butano/hw/src/*.s")
file(GLOB common "${butano}/common/src/*.cpp")

# 3rd party code
file(GLOB_RECURSE cpp_3rd_party "${butano}/butano/hw/3rd_party/*.cpp")
file(GLOB_RECURSE c_3rd_party "${butano}/butano/hw/3rd_party/*.c")
file(GLOB_RECURSE asm_3rd_party "${butano}/butano/hw/3rd_party/*.s")

add_library(butano OBJECT ${src} ${hw_src} ${hw_asm} ${common}
    ${cpp_3rd_party}
    ${c_3rd_party}
    ${asm_3rd_party}
)

target_include_directories(butano PUBLIC
    "${butano}/butano/include"
    "${butano}/common/include"
    "${butano}/butano/hw/3rd_party/libtonc/include"
)
target_include_directories(butano PRIVATE "${butano}/butano/hw/3rd_party/libugba/include")
target_compile_features(butano PUBLIC cxx_std_20)

set(ARCH -mthumb -mthumb-interwork)
set(CWARNINGS -Wall -Wextra -Wpedantic -Wshadow -Wundef -Wunused-parameter -Wmisleading-indentation -Wduplicated-cond
        -Wduplicated-branches -Wlogical-op -Wnull-dereference -Wswitch-default -Wstack-usage=16384)
set(CFLAGS ${CWARNINGS} -mcpu=arm7tdmi -mtune=arm7tdmi -ffast-math -ffunction-sections -fdata-sections ${ARCH})
set(CPPWARNINGS -Wuseless-cast -Wnon-virtual-dtor -Woverloaded-virtual)

target_compile_options(butano PRIVATE
    $<$<COMPILE_LANGUAGE:ASM>:${ARCH} -x assembler-with-cpp>
    $<$<COMPILE_LANGUAGE:C>:${CFLAGS}>
    $<$<COMPILE_LANGUAGE:CXX>:${CFLAGS} ${CPPWARNINGS} -fno-rtti -fno-exceptions -fno-threadsafe-statics -fuse-cxa-atexit>
    $<$<CONFIG:Debug>:-Og -g>
    $<$<CONFIG:Release>:-O2>
)

# Set IWRAM compile options
get_target_property(iwramSources butano SOURCES)
list(FILTER iwramSources INCLUDE REGEX ".+\\.bn_iwram\\..+")
set_source_files_properties(${iwramSources} PROPERTIES COMPILE_FLAGS "-fno-lto -marm -mlong-calls -O2")

# Set EWRAM compile options
get_target_property(ewramSources butano SOURCES)
list(FILTER ewramSources INCLUDE REGEX ".+\\.bn_ewram\\..+")
set_source_files_properties(${ewramSources} PROPERTIES COMPILE_FLAGS "-fno-lto -O2")

# Set no-flto compile options
get_target_property(nofltoSources butano SOURCES)
list(FILTER nofltoSources INCLUDE REGEX ".+\\.bn_noflto\\..+")
set_source_files_properties(${nofltoSources} PROPERTIES COMPILE_FLAGS "-fno-lto")

# Butano dependencies
if(NOT TARGET maxmod)
    find_package(maxmod REQUIRED)
endif()

target_link_libraries(butano PUBLIC maxmod)

# Butano tools
if(NOT Python_EXECUTABLE)
    find_package(Python COMPONENTS Interpreter REQUIRED)
endif()

find_file(butano_assets_tool NAMES "butano/tools/butano_assets_tool.py" PATHS "${butano}" NO_CACHE)

function(add_butano_asset_subdirectory name)
    set(multiValueArgs
        AUDIO
        DMG_AUDIO
        GRAPHICS
    )
    cmake_parse_arguments(ARGS "" "" "${multiValueArgs}" ${ARGN})

    list(APPEND ARGS_GRAPHICS "${butano}/common/graphics")

    # Add dummy directory if needed
    if(NOT ARGS_AUDIO OR NOT ARGS_DMG_AUDIO)
        file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/bn_empty_assets")
        if(NOT ARGS_AUDIO)
            set(ARGS_AUDIO "${CMAKE_BINARY_DIR}/bn_empty_assets")
        endif()
        if(NOT ARGS_DMG_AUDIO)
            set(ARGS_DMG_AUDIO "${CMAKE_BINARY_DIR}/bn_empty_assets")
        endif()
    endif()

    # Define the output
    set(binaryDir "${CMAKE_BINARY_DIR}/bn_${name}_assets")
    unset(outputs)
    unset(outputSources)

    # Add graphics outputs
    foreach(dir ${ARGS_GRAPHICS})
        file(GLOB inputs "${CMAKE_SOURCE_DIR}/${dir}/*.json")
        foreach(input ${inputs})
            get_filename_component(output "${input}" NAME_WE)
            list(APPEND outputs
                "${binaryDir}/_bn_${output}_graphics_file_info.txt"
                "${binaryDir}/${output}_bn_gfx.s"
            )
            list(APPEND outputSources "${binaryDir}/${output}_bn_gfx.s")
        endforeach()
    endforeach()

    # Add audio outputs
    list(APPEND outputs "${binaryDir}/_bn_audio_files_info.txt")
    list(APPEND outputs "${binaryDir}/_bn_audio_soundbank.bin")

    # Add dmg_audio outputs
    foreach(dir ${ARGS_DMG_AUDIO})
        file(GLOB inputs "${CMAKE_SOURCE_DIR}/${dir}/*")
        foreach(input ${inputs})
            get_filename_component(extension "${input}" EXT)
            if(extension STREQUAL ".json")
                continue()
            endif()

            get_filename_component(output "${input}" NAME_WE)
            list(APPEND outputs "${binaryDir}/${output}_bn_dmg.c")
            list(APPEND outputSources "${binaryDir}/${output}_bn_dmg.c")
        endforeach()
    endforeach()

    # Add path to mmutil
    get_filename_component(mmutil_bin "${CMAKE_MMUTIL_PROGRAM}" DIRECTORY)

    add_custom_command(
        OUTPUT ${outputs}
        COMMAND "${CMAKE_COMMAND}" -E env "PATH=$ENV{PATH};${mmutil_bin}" "${Python_EXECUTABLE}" "${butano_assets_tool}"
            --audio="${ARGS_AUDIO}"
            --dmg_audio="${ARGS_DMG_AUDIO}"
            --graphics="${ARGS_GRAPHICS}"
            --build="${binaryDir}"
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    )

    if(NOT CMAKE_BIN2S_PROGRAM)
        add_custom_command(
            OUTPUT "${binaryDir}/_bn_audio_soundbank.s"
            COMMAND "${CMAKE_COMMAND}" -D "-DINPUTS=_bn_audio_soundbank.bin" "-DOUTPUT=_bn_audio_soundbank.s" -P "${ASSET_SCRIPT}"
            DEPENDS "${binaryDir}/_bn_audio_soundbank.bin"
            VERBATIM
            WORKING_DIRECTORY "${binaryDir}"
        )
    else()
        add_custom_command(
            OUTPUT "${binaryDir}/_bn_audio_soundbank.s"
            COMMAND "${CMAKE_BIN2S_PROGRAM}" "_bn_audio_soundbank.bin" > "_bn_audio_soundbank.s"
            DEPENDS "${binaryDir}/_bn_audio_soundbank.bin"
            VERBATIM
            COMMAND_EXPAND_LISTS
            WORKING_DIRECTORY "${binaryDir}"
        )
    endif()

    add_library(${name} OBJECT ${outputSources} "${binaryDir}/_bn_audio_soundbank.s")
    target_include_directories(${name} INTERFACE "${binaryDir}")
endfunction()
