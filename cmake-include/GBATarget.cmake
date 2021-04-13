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

    if(NOT ${version} MATCHES "^[0-9]+$")
        message(FATAL_ERROR "gba_target_fix version ${version} must be a number!")
    endif()

    add_custom_command(TARGET ${target}
        POST_BUILD
        COMMAND "${GBA_TOOLCHAIN_GBAFIX}" "${inputOutput}" "-t${title}" "-c${gameCode}" "-m${makerCode}" "-r${version}"
        COMMENT "GBA header-fix \"${title}\" ${gameCode}:${makerCode} version ${version}"
    )
endfunction()

function(gba_target_sources_instruction_set target default)
    cmake_minimum_required(VERSION 3.0)

    get_target_property(TARGET_SOURCES ${target} SOURCES)

    foreach(SOURCE ${TARGET_SOURCES})
        string(REGEX MATCH "(.*\\.iwram[0-9]?\\..*)" SOURCE_IWRAM ${SOURCE})
        string(REGEX MATCH "(.*\\.ewram[0-9]?\\..*)" SOURCE_EWRAM ${SOURCE})

        if(NOT "${SOURCE_IWRAM}" STREQUAL "")
            set_source_files_properties(${SOURCE} PROPERTIES COMPILE_FLAGS "-marm -mlong-calls")
        endif()

        if(NOT "${SOURCE_EWRAM}" STREQUAL "")
            set_source_files_properties(${SOURCE} PROPERTIES COMPILE_FLAGS "-mthumb -mlong-calls")
        endif()

        if("${SOURCE_IWRAM}" STREQUAL "" AND "${SOURCE_EWRAM}" STREQUAL "")
            set_source_files_properties(${SOURCE} PROPERTIES COMPILE_FLAGS "-m${default}")
        endif()
    endforeach()
endfunction()

function(gba_target_link_tonc target)
    cmake_minimum_required(VERSION 3.0)

    add_subdirectory("${GBA_TOOLCHAIN_LIB_TONC_DIR}" "./tonc")
    target_link_libraries(${target} PRIVATE tonc)
    target_include_directories(${target} PUBLIC "${GBA_TOOLCHAIN_LIB_TONC_DIR}/include")
endfunction()

function(gba_target_link_maxmod target)
    cmake_minimum_required(VERSION 3.0)

    add_subdirectory("${GBA_TOOLCHAIN_LIB_MAXMOD_DIR}" "./maxmod")
    target_link_libraries(${target} PRIVATE maxmod)
    target_include_directories(${target} PUBLIC "${GBA_TOOLCHAIN_LIB_MAXMOD_DIR}/include")
endfunction()

function(gba_target_link_gbfs target)
    cmake_minimum_required(VERSION 3.0)

    add_subdirectory("${GBA_TOOLCHAIN_LIB_GBFS_DIR}" "./gbfs")
    target_link_libraries(${target} PRIVATE gbfs)
    target_include_directories(${target} PUBLIC "${GBA_TOOLCHAIN_LIB_GBFS_DIR}/include")
endfunction()

function(gba_target_link_agb_abi target)
    cmake_minimum_required(VERSION 3.0)

    add_subdirectory("${GBA_TOOLCHAIN_LIB_AGBABI_DIR}" "./agbabi")
    target_link_libraries(${target} PRIVATE agbabi)
    target_include_directories(${target} PUBLIC "${GBA_TOOLCHAIN_LIB_AGBABI_DIR}/include")
    target_compile_definitions(${target} PRIVATE __agb_abi=1)
endfunction()

function(gba_target_link_gba_plusplus target)
    cmake_minimum_required(VERSION 3.0)

    target_include_directories(${target} PUBLIC "${GBA_TOOLCHAIN_LIB_GBA_PLUSPLUS_DIR}/include")
endfunction()

function(gba_add_gbfs_target target)
    cmake_minimum_required(VERSION 3.0)

    list(TRANSFORM ARGN PREPEND "${CMAKE_CURRENT_SOURCE_DIR}/")
    get_filename_component(GBFS_FILE_WE "${target}" NAME_WE)

    add_custom_target(${target}
        COMMAND "${GBA_TOOLCHAIN_GBFS}" "${target}" ${ARGN}
        DEPENDS ${ARGN}
        BYPRODUCTS "${target}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        COMMENT "GBFS -> \"${target}\""
    )
endfunction()

function(gba_target_add_gbfs_dependency target dependency)
    cmake_minimum_required(VERSION 3.0)

    get_filename_component(GBFS_FILE_WE "${dependency}" NAME_WE)

    add_custom_target("${dependency}.s"
        COMMAND "${GBA_TOOLCHAIN_BIN2S}" "${dependency}" > "${GBFS_FILE_WE}.s"
        DEPENDS "${dependency}"
        BYPRODUCTS "${GBFS_FILE_WE}.s"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        SOURCES "${GBFS_FILE_WE}.s"
    )
    add_dependencies("${dependency}.s" ${dependency})

    add_dependencies(${target} "${dependency}.s")
    target_sources(${target} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/${GBFS_FILE_WE}.s")
endfunction()
