function(gba_target_link_runtime target library)
    cmake_minimum_required(VERSION 3.0)

    if("${library}" STREQUAL "rom")
        add_subdirectory("${GBA_TOOLCHAIN_LIB_ROM_DIR}" "./${library}")
    elseif("${library}" STREQUAL "multiboot")
        add_subdirectory("${GBA_TOOLCHAIN_LIB_MULTIBOOT_DIR}" "./${library}")
    else()
        message(FATAL_ERROR "gba_target_link_runtime unknown library \"${library}\"")
    endif()

    add_dependencies(${target} ${library})
    target_link_libraries(${target} PRIVATE "-specs=${library}/runtime.specs")
endfunction()

function(gba_target_object_copy target input output)
    cmake_minimum_required(VERSION 3.0)

    add_custom_command(TARGET ${target}
        POST_BUILD
        COMMAND "${CMAKE_OBJCOPY}" -O binary "${input}" "${output}"
        COMMENT "Object copy -> \"${output}\""
        BYPRODUCTS "${output}"
    )
endfunction()

function(gba_target_fix target inputOutput title gameCode makerCode version)
    cmake_minimum_required(VERSION 3.0)

    string(LENGTH "${title}" TITLE_LENGTH)
    if (${TITLE_LENGTH} GREATER 12)
        message(FATAL_ERROR "gba_target_fix title \"${title}\" must not be more than 12 characters!")
    endif()

    string(LENGTH "${gameCode}" GAME_CODE_LENGTH)
    if (NOT ${GAME_CODE_LENGTH} EQUAL 4)
        message(FATAL_ERROR "gba_target_fix gameCode \"${gameCode}\" must be 4 characters!")
    endif()

    string(LENGTH "${makerCode}" MAKER_CODE_LENGTH)
    if (NOT ${MAKER_CODE_LENGTH} EQUAL 2)
        message(FATAL_ERROR "gba_target_fix makerCode \"${makerCode}\" must be 2 characters!")
    endif()

    string(LENGTH "${makerCode}" MAKER_CODE_LENGTH)
    if (${version} GREATER 255)
        message(FATAL_ERROR "gba_target_fix version ${version} must be less than 256!")
    endif()

    add_custom_command(TARGET ${target}
        POST_BUILD
        COMMAND "${GBA_TOOLCHAIN_GBAFIX}" "${inputOutput}" "-t${title}" "-c${gameCode}" "-m${makerCode}" -r${version}
        COMMENT "GBA header-fix \"${title}\" ${gameCode}:${makerCode} version ${version}"
        BYPRODUCTS "${inputOutput}"
    )
endfunction()

function(gba_target_sources_instruction_set target default)
    get_target_property(TARGET_SOURCES ${target} SOURCES)

    foreach(SOURCE ${TARGET_SOURCES})
        string(REGEX MATCH "(.*\\.iwram\\..*)" SOURCE_IWRAM ${SOURCE})
        string(REGEX MATCH "(.*\\.ewram\\..*)" SOURCE_EWRAM ${SOURCE})

        if(NOT "${SOURCE_IWRAM}" STREQUAL "")
            message(STATUS "iwram ${SOURCE_IWRAM}")
            set_source_files_properties(${SOURCE} PROPERTIES COMPILE_FLAGS "-marm -mlong-calls")
        endif()

        if(NOT "${SOURCE_EWRAM}" STREQUAL "")
            message(STATUS "ewram ${SOURCE_EWRAM}")
            set_source_files_properties(${SOURCE} PROPERTIES COMPILE_FLAGS "-mthumb -mlong-calls")
        endif()

        if("${SOURCE_IWRAM}" STREQUAL "" AND "${SOURCE_EWRAM}" STREQUAL "")
            message(STATUS "default ${default}")
            set_source_files_properties(${SOURCE} PROPERTIES COMPILE_FLAGS "-m${default}")
        endif()
    endforeach()
endfunction()

function(gba_target_link_tonc target)
    add_subdirectory("${GBA_TOOLCHAIN_LIB_TONC_DIR}" "./tonc")
    target_link_libraries(${target} PRIVATE tonc)
    target_include_directories(${target} PUBLIC "${GBA_TOOLCHAIN_LIB_TONC_DIR}/include")
endfunction()
