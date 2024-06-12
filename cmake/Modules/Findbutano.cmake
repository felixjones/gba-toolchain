#===============================================================================
#
# Fetches Butano and provides the `add_butano_library` function
#   Also provides the `butano-common` global Butano library target.
#   `add_butano_library` compiles graphics, audio, and DMG audio into an object library to be linked.
#
# Multiple Butano libraries may be linked together, however a target cannot directly link with multiple Butano libraries:
#   ```cmake
#   add_butano_library(library-A GRAPHICS image.bmp)
#   add_butano_library(library-B AUDIO sound.wav)
#   # target_link_libraries(my_target PRIVATE library-A library-B)  # Do not do this
#   target_link_libraries(library-A INTERFACE library-B)  # Instead, link the libraries together
#   target_link_libraries(my_target PRIVATE library-A)  # And then link with a single Butano library
#   ```
#
# If butano-common is desired, it may be linked to another Butano library:
#   ```cmake
#   add_butano_library(library-A GRAPHICS image.bmp)
#   target_link_libraries(library-A INTERFACE butano-common)  # Link with butano-common
#   target_link_libraries(my_target PRIVATE library-A)
#   ```
#
# Butano libraries also provide an INTERFACE link to butano-runtime for convenience.
#
# Butano libraries have the following properties:
#   `BUTANO_SOURCES` list of source paths relative to `CMAKE_CURRENT_SOURCE_DIR`.
#
# Example:
#   ```cmake
#   file(GLOB_RECURSE graphics CONFIGURE_DEPENDS graphics/*.bmp)
#   file(GLOB_RECURSE audio CONFIGURE_DEPENDS audio/*.wav audio/*.it)
#   file(GLOB_RECURSE dmg_audio CONFIGURE_DEPENDS dmg_audio/*.vgm dmg_audio/*.s3m)
#   add_butano_library(my_butano_assets
#        GRAPHICS ${graphics}
#        AUDIO ${audio}
#        DMG_AUDIO ${dmg_audio}
#   )
#   target_link_libraries(my_target PRIVATE my_butano_assets)
#   ```
#
# Add Butano library command:
#   `add_butano_library(<target> [GRAPHICS <file-path>...] [AUDIO <file-path>...] [DMG_AUDIO <file-path>...])`
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

if(NOT Python_EXECUTABLE)
    find_package(Python COMPONENTS Interpreter REQUIRED)
endif()

include(Depfile)
include(Bin2o)
include(CommonDir)
find_package(grit REQUIRED)
find_package(maxmod REQUIRED)

function(add_butano_library target)
    set(bnTargetDir "_butano/${target}.dir")
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}")
    set(sourcesEval $<TARGET_PROPERTY:${target},INTERFACE_SOURCES>)

    set(assetScript "${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/bn_assets.cmake")
    file(WRITE "${assetScript}" [=[
include(${DEPFILE_PATH} OPTIONAL RESULT_VARIABLE found)
if(NOT found)
    message(FATAL_ERROR "Could not include Depfile.cmake (tried ${DEPFILE_PATH})")
endif()
include(${BIN2O_PATH} OPTIONAL RESULT_VARIABLE found)
if(NOT found)
    message(FATAL_ERROR "Could not include Bin2o.cmake (tried ${BIN2O_PATH})")
endif()
include(${COMMON_DIR_PATH} OPTIONAL RESULT_VARIABLE found)
if(NOT found)
    message(FATAL_ERROR "Could not include CommonDir.cmake (tried ${COMMON_DIR_PATH})")
endif()

foreach(ii RANGE ${CMAKE_ARGC})
    if(${ii} EQUAL ${CMAKE_ARGC})
        break()
    elseif("${CMAKE_ARGV${ii}}" STREQUAL --)
        set(start ${ii})
    elseif(DEFINED start)
        list(APPEND SCRIPT_ARGN "${CMAKE_ARGV${ii}}")
    endif()
endforeach()
unset(start)

list(GET SCRIPT_ARGN 0 target)
list(GET SCRIPT_ARGN 1 argsFile)
file(READ "${argsFile}" arguments)
string(REPLACE " " ";" arguments ${arguments})

foreach(arg ${arguments})
    if(arg MATCHES "/GRAPHICS$")
        set(mode GRAPHICS)
        continue()
    endif()
    if(arg MATCHES "/AUDIO$")
        set(mode AUDIO)
        continue()
    endif()
    if(arg MATCHES "/DMG_AUDIO$")
        set(mode DMG_AUDIO)
        continue()
    endif()
    if(arg MATCHES "/END$")
        unset(mode)
        continue()
    endif()

    if(NOT mode)
        continue()
    endif()

    list(APPEND bn${mode} ${arg})
endforeach()

common_dir(workingDirectory ${bnAUDIO} ${bnDMG_AUDIO} ${bnGRAPHICS})

foreach(input ${bnGRAPHICS})
    get_filename_component(name "${input}" NAME_WE)
    get_filename_component(directory "${input}" DIRECTORY)
    if(EXISTS "${directory}/${name}.json")
        list(APPEND input "${directory}/${name}.json")
    endif()
    list(APPEND depGraphics
        TARGETS "${name}_bn_gfx.o"
        DEPENDENCIES ${input}
    )
    list(APPEND graphicsUnity "${name}_bn_gfx.s")
endforeach()

if(NOT bnAUDIO)
    set(bnAUDIO _bn_dummy_audio_file.txt)
endif()

set(depAudio
    TARGETS _bn_audio_soundbank.o bn_music_items_info.h bn_sound_items_info.h
    DEPENDENCIES ${bnAUDIO}
)

foreach(input ${bnDMG_AUDIO})
    get_filename_component(name "${input}" NAME_WE)
    get_filename_component(directory "${input}" DIRECTORY)
    if(EXISTS "${directory}/${name}.json")
        list(APPEND input "${directory}/${name}.json")
    endif()
    list(APPEND depAudioDmg
        TARGETS "${name}_bn_dmg.o"
        DEPENDENCIES ${input}
    )
    list(APPEND dmgUnity "${name}_bn_dmg.c")
endforeach()

depfile(${target}.d
    ${depGraphics}
    ${depAudio}
    ${depAudioDmg}
)

foreach(input ${bnAUDIO})
    if(NOT IS_ABSOLUTE "${input}")
        continue()
    elseif(UNIX AND NOT input MATCHES "^/")
        set(input "/${input}")
    endif()
    file(RELATIVE_PATH input "${workingDirectory}" "${input}")
    list(APPEND audioInputs "${input}")
endforeach()

foreach(input ${bnDMG_AUDIO})
    if(NOT IS_ABSOLUTE "${input}")
        continue()
    elseif(UNIX AND NOT input MATCHES "^/")
        set(input "/${input}")
    endif()
    file(RELATIVE_PATH input "${workingDirectory}" "${input}")
    list(APPEND dmgAudioInputs "${input}")
endforeach()

foreach(input ${bnGRAPHICS})
    if(NOT IS_ABSOLUTE "${input}")
        continue()
    elseif(UNIX AND NOT input MATCHES "^/")
        set(input "/${input}")
    endif()
    file(RELATIVE_PATH input "${workingDirectory}" "${input}")
    list(APPEND graphicsInputs "${input}")
endforeach()

string(JOIN " " audioInputs ${audioInputs})
string(JOIN " " dmgAudioInputs ${dmgAudioInputs})
string(JOIN " " graphicsInputs ${graphicsInputs})

# Run Butano assets tool
execute_process(
    COMMAND "${Python_EXECUTABLE}" "${BUTANO_ASSETS_TOOL_PATH}"
        --grit ${GRIT_PATH}
        --mmutil ${MMUTIL_PATH}
        --audio "${audioInputs}"
        --dmg_audio "${dmgAudioInputs}"
        --graphics "${graphicsInputs}"
        --build ${CMAKE_CURRENT_LIST_DIR}
    WORKING_DIRECTORY "${workingDirectory}"
    RESULT_VARIABLE result
)

if(result)
    return()
endif()

# Create soundbank object file
bin2o(_bn_audio_soundbank.o _bn_audio_soundbank.bin)

# Create graphics unity source
foreach(path ${graphicsUnity})
    if(EXISTS "${path}")
        list(APPEND graphicsSources "${path}")
    endif()
endforeach()
if(graphicsSources)
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E cat ${graphicsSources}
        OUTPUT_FILE "_bn_graphics.unity.s"
    )
else()
    file(TOUCH "_bn_graphics.unity.s")
endif()

# Create DMG Audio unity source
foreach(path ${dmgUnity})
    if(EXISTS "${path}")
        list(APPEND dmgSources "${path}")
    endif()
endforeach()
if(dmgSources)
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E cat ${dmgSources}
        OUTPUT_FILE "_bn_dmg_audio.unity.c"
    )
else()
    file(TOUCH "_bn_dmg_audio.unity.c")
endif()
]=])

    file(GENERATE OUTPUT "${bnTargetDir}/_bn_${target}_inputs.txt" CONTENT "$<JOIN:${sourcesEval}, >" TARGET ${target}})

    add_custom_command(OUTPUT "${bnTargetDir}/_bn_audio_soundbank.o" "${bnTargetDir}/_bn_graphics.unity.o" "${bnTargetDir}/_bn_dmg_audio.unity.o"
            DEPENDS "${sourcesEval}"
            DEPFILE "${bnTargetDir}/${target}.d"
            BYPRODUCTS "${bnTargetDir}/_bn_audio_soundbank.bin" "${bnTargetDir}/_bn_audio_files_info.txt" "${bnTargetDir}/_bn_graphics.unity.s" "${bnTargetDir}/_bn_dmg_audio.unity.c"
            # Run script
            COMMAND "${CMAKE_COMMAND}"
                -D DEPFILE_PATH=${DEPFILE_PATH}
                -D BIN2O_PATH=${BIN2O_PATH}
                -D COMMON_DIR_PATH=${COMMON_DIR_PATH}
                -D GRIT_PATH=${GRIT_PATH}
                -D MMUTIL_PATH=${MMUTIL_PATH}
                -D BUTANO_ASSETS_TOOL_PATH=${BUTANO_ASSETS_TOOL_PATH}
                -D Python_EXECUTABLE=${Python_EXECUTABLE}
                -D CMAKE_LINKER="${CMAKE_LINKER}"
                -D CMAKE_OBJCOPY="${CMAKE_OBJCOPY}"
                -P "${assetScript}" -- ${target} "_bn_${target}_inputs.txt"
                > $<IF:$<BOOL:${CMAKE_HOST_WIN32}>,NUL,/dev/null> # Silence stdout
            # Compile _bn_graphics.unity.o
            COMMAND "${CMAKE_ASM_COMPILER}" "-c" "-o" "_bn_graphics.unity.o" "_bn_graphics.unity.s"
            # Compile _bn_dmg_audio.unity.o
            COMMAND "${CMAKE_C_COMPILER}" "-c" "-o" "_bn_dmg_audio.unity.o" "_bn_dmg_audio.unity.c"
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}"
            COMMAND_EXPAND_LISTS
    )

    foreach(arg ${ARGN})
        if(arg STREQUAL GRAPHICS OR arg STREQUAL AUDIO OR arg STREQUAL DMG_AUDIO)
            set(mode ${arg})
            continue()
        endif()

        if(NOT mode)
            message(FATAL_ERROR "Source ${arg} must be preceded by valid mode [GRAPHICS|AUDIO|DMG_AUDIO]")
        endif()

        if(NOT IS_ABSOLUTE "${arg}")
            file(REAL_PATH "${arg}" arg BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
        endif()
        if(NOT EXISTS "${arg}")
            message(FATAL_ERROR "Cannot find ${arg}")
        endif()

        list(APPEND bn${mode} ${arg})
    endforeach()

    file(TOUCH
            "${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/GRAPHICS"
            "${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/AUDIO"
            "${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/DMG_AUDIO"
            "${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/END"
    )

    add_library(${target} OBJECT IMPORTED)
    set_target_properties(${target} PROPERTIES
            IMPORTED_OBJECTS "${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/_bn_audio_soundbank.o;${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/_bn_graphics.unity.o;${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/_bn_dmg_audio.unity.o"
            BUTANO_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/GRAPHICS;${bnGRAPHICS};${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/AUDIO;${bnAUDIO};${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/DMG_AUDIO;${bnDMG_AUDIO};${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}/END"
    )
    target_sources(${target} INTERFACE
            $<TARGET_PROPERTY:${target},BUTANO_SOURCES>
            $<TARGET_OBJECTS:butano-runtime>
    )
    target_include_directories(${target} INTERFACE
            "${CMAKE_CURRENT_BINARY_DIR}/${bnTargetDir}"
            $<TARGET_PROPERTY:butano-runtime,INTERFACE_INCLUDE_DIRECTORIES>
    )
    target_compile_features(${target} INTERFACE cxx_std_20)
endfunction()

include(FetchContent)
include(Mktemp)

mktemp(butanoCMakeLists TMPDIR)
file(WRITE "${butanoCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(butano LANGUAGES ASM C CXX VERSION 17.6.0)

# Butano sources
file(GLOB src CONFIGURE_DEPENDS "butano/src/*.cpp")
file(GLOB hw_src CONFIGURE_DEPENDS "butano/hw/src/*.cpp")
file(GLOB hw_asm CONFIGURE_DEPENDS "butano/hw/src/*.s")

# 3rd party code
file(GLOB_RECURSE cpp_3rd_party CONFIGURE_DEPENDS "butano/hw/3rd_party/*.cpp")
file(GLOB_RECURSE c_3rd_party CONFIGURE_DEPENDS "butano/hw/3rd_party/*.c")
file(GLOB_RECURSE asm_3rd_party CONFIGURE_DEPENDS "butano/hw/3rd_party/*.s")

add_library(butano-runtime OBJECT ${src} ${hw_src} ${hw_asm}
    ${cpp_3rd_party}
    ${c_3rd_party}
    ${asm_3rd_party}
)

target_include_directories(butano-runtime
    PUBLIC
        butano/include
        butano/hw/3rd_party/libtonc/include
    PRIVATE
        butano/hw/3rd_party/libugba/include
        butano/hw/3rd_party/maxmod/include
)

target_compile_features(butano-runtime PRIVATE cxx_std_20)

set(ARCH -mthumb -mthumb-interwork)
set(CWARNINGS -Wall -Wextra -Wpedantic -Wshadow -Wundef -Wunused-parameter -Wmisleading-indentation -Wduplicated-cond -Wduplicated-branches -Wlogical-op -Wnull-dereference -Wswitch-default -Wstack-usage=16384)
set(CFLAGS ${CWARNINGS} -gdwarf-4 -O2 -mcpu=arm7tdmi -mtune=arm7tdmi -ffast-math -ffunction-sections -fdata-sections ${ARCH})
set(CPPWARNINGS -Wuseless-cast -Wnon-virtual-dtor -Woverloaded-virtual)

target_compile_options(butano-runtime PRIVATE
    $<$<COMPILE_LANGUAGE:ASM>:${ARCH} -x assembler-with-cpp>
    $<$<COMPILE_LANGUAGE:C>:${CFLAGS}>
    $<$<COMPILE_LANGUAGE:CXX>:${CFLAGS} ${CPPWARNINGS} -fno-rtti -fno-exceptions -fno-threadsafe-statics -fuse-cxa-atexit>
)

target_compile_definitions(butano-runtime PUBLIC
    BN_TOOLCHAIN_TAG="gba-toolchain"
    BN_EWRAM_BSS_SECTION=".sbss"
    BN_IWRAM_START=__iwram_start__
    BN_IWRAM_TOP=__iwram_top
    BN_IWRAM_END=__fini_array_end
    BN_ROM_START=__start
    BN_ROM_END=__rom_end
)

# Set IWRAM compile options
get_target_property(iwramSources butano-runtime SOURCES)
list(FILTER iwramSources INCLUDE REGEX ".+\\.bn_iwram\\..+")
set_source_files_properties(${iwramSources} PROPERTIES COMPILE_FLAGS "-fno-lto -marm -mlong-calls")

# Set EWRAM compile options
get_target_property(ewramSources butano-runtime SOURCES)
list(FILTER ewramSources INCLUDE REGEX ".+\\.bn_ewram\\..+")
set_source_files_properties(${ewramSources} PROPERTIES COMPILE_FLAGS "-fno-lto")

# Set no-flto compile options
get_target_property(nofltoSources butano-runtime SOURCES)
list(FILTER nofltoSources INCLUDE REGEX ".+\\.bn_noflto\\..+")
set_source_files_properties(${nofltoSources} PROPERTIES COMPILE_FLAGS "-fno-lto")
]=])

FetchContent_Declare(butano
        GIT_REPOSITORY "https://github.com/GValiente/butano.git"
        GIT_TAG "17.6.0"
        PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${butanoCMakeLists}" "CMakeLists.txt"
)
FetchContent_MakeAvailable(butano)
file(REMOVE "${butanoCMakeLists}")

find_file(BUTANO_ASSETS_TOOL_PATH NAMES "butano_assets_tool.py" PATHS "${butano_SOURCE_DIR}/butano/tools")

# Add the Butano common library
if(NOT TARGET butano-common)
    file(GLOB graphics CONFIGURE_DEPENDS "${butano_SOURCE_DIR}/common/graphics/*.bmp")
    add_butano_library(butano-common GRAPHICS ${graphics})
    file(GLOB sources CONFIGURE_DEPENDS "${butano_SOURCE_DIR}/common/src/*.cpp")
    target_sources(butano-common INTERFACE ${sources})
    target_include_directories(butano-common INTERFACE "${butano_SOURCE_DIR}/common/include")
endif()
