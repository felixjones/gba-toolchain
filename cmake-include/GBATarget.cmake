include(ExternalProject OPTIONAL RESULT_VARIABLE GBA_TOOLCHAIN_HAS_MODULE_EXTERNALPROJECT)

function(gba_target_link_runtime target library)
    cmake_minimum_required(VERSION 3.0)

    if("${library}" STREQUAL "rom")
        add_subdirectory("${GBA_TOOLCHAIN_LIB_ROM_DIR}" "./${library}")
    elseif("${library}" STREQUAL "multiboot")
        add_subdirectory("${GBA_TOOLCHAIN_LIB_MULTIBOOT_DIR}" "./${library}")
    elseif("${library}" STREQUAL "ereader")
        add_subdirectory("${GBA_TOOLCHAIN_LIB_EREADER_DIR}" "./${library}")
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

    # Padding using gbfs padbin
    if(ARGN)
        gba_target_add_gbfs_external_project(${target})

        list(GET ARGN 0 padding)

        add_custom_command(TARGET ${target}
            POST_BUILD
            COMMAND "${GBA_TOOLCHAIN_PADBIN}" ${padding} "${output}"
            COMMENT "Padding ${padding} -> \"${output}\""
        )
    endif()
endfunction()

function(gba_target_add_gbfs_external_project target)
    cmake_minimum_required(VERSION 3.0)

    if (NOT TARGET gbfs)
        if(NOT ${GBA_TOOLCHAIN_HAS_MODULE_EXTERNALPROJECT} STREQUAL "NOTFOUND")
            ExternalProject_Add(gbfs
                SOURCE_DIR "${GBA_TOOLCHAIN_TOOLS}/gbfs"
                BINARY_DIR "${GBA_TOOLCHAIN_TOOLS}/gbfs"
                PREFIX "${GBA_TOOLCHAIN_TOOLS}/gbfs"
                INSTALL_COMMAND ""
            )
        endif()
    endif()

    add_dependencies(${target} gbfs)
endfunction()

function(gba_target_fix target inputOutput title gameCode makerCode version)
    cmake_minimum_required(VERSION 3.0)

    if(NOT ${GBA_TOOLCHAIN_HAS_MODULE_EXTERNALPROJECT} STREQUAL "NOTFOUND")
        ExternalProject_Add(gbafix
            SOURCE_DIR "${GBA_TOOLCHAIN_TOOLS}/gbafix"
            BINARY_DIR "${GBA_TOOLCHAIN_TOOLS}/gbafix"
            PREFIX "${GBA_TOOLCHAIN_TOOLS}/gbafix"
            INSTALL_COMMAND ""
        )

        add_dependencies(${target} gbafix)
    endif()

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

    gba_target_add_gbfs_external_project(${target})

    add_subdirectory("${GBA_TOOLCHAIN_LIB_GBFS_DIR}" "./gbfs")
    target_link_libraries(${target} PRIVATE libgbfs)
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

    add_custom_target(${target}
        COMMAND "${GBA_TOOLCHAIN_GBFS}" "${target}" ${ARGN}
        DEPENDS ${ARGN}
        BYPRODUCTS "${target}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        COMMENT "GBFS -> \"${target}\""
    )
endfunction()

function(gba_target_append_gbfs target gbfs input)
    cmake_minimum_required(VERSION 3.0)

    if (NOT TARGET gbfs)
        message(FATAL_ERROR "${gbfs} is not a target")
    endif()

    add_dependencies(${target} ${gbfs})

    if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
        add_custom_command(TARGET ${target}
            POST_BUILD
            COMMAND copy /B "${input}" + "${gbfs}" "${input}"
            COMMENT "File cat \"${gbfs}\" -> \"${input}\""
            BYPRODUCTS "${input}"
        )
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux OR CMAKE_HOST_SYSTEM_NAME STREQUAL Darwin OR CMAKE_HOST_SYSTEM_NAME MATCHES "MING.*" OR CMAKE_HOST_SYSTEM_NAME MATCHES "MSYS.*")
        add_custom_command(TARGET ${target}
            POST_BUILD
            COMMAND cat "${gbfs}" >> "${input}"
            COMMENT "File cat \"${gbfs}\" -> \"${input}\""
            BYPRODUCTS "${input}"
        )
    else()
        message(FATAL_ERROR "Failed to recognise host operating system (${CMAKE_HOST_SYSTEM_NAME})")
    endif()
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

function(gba_target_link_posprintf target)
    cmake_minimum_required(VERSION 3.0)

    add_subdirectory("${GBA_TOOLCHAIN_LIB_POSPRINTF_DIR}" "./posprintf")
    target_link_libraries(${target} PRIVATE posprintf)
    target_include_directories(${target} PUBLIC "${GBA_TOOLCHAIN_LIB_POSPRINTF_DIR}")
    target_compile_definitions(${target} PRIVATE __posprintf=1)
endfunction()

function(gba_target_archive_dotcode target input output region)
    cmake_minimum_required(VERSION 3.0)

    if(NOT ${GBA_TOOLCHAIN_HAS_MODULE_EXTERNALPROJECT} STREQUAL "NOTFOUND")
        ExternalProject_Add(nedclib
            SOURCE_DIR "${GBA_TOOLCHAIN_TOOLS}/nedclib"
            BINARY_DIR "${GBA_TOOLCHAIN_TOOLS}/nedclib"
            PREFIX "${GBA_TOOLCHAIN_TOOLS}/nedclib"
            INSTALL_COMMAND ""
        )

        add_dependencies(${target} nedclib)
    endif()

    get_filename_component(OUTPUT_FILE_WLE ${output} NAME_WLE)

    if("${region}" STREQUAL "original")
        set(NEDCMAKE_TYPE "1")
        set(NEDCMAKE_REGION "0")

        message(FATAL_ERROR "gba_target_archive_dotcode \"original\" region not yet implemented")
    elseif("${region}" STREQUAL "non-japan")
        set(NEDCMAKE_TYPE "2")
        set(NEDCMAKE_REGION "1")
    elseif("${region}" STREQUAL "japan-plus")
        set(NEDCMAKE_TYPE "2")
        set(NEDCMAKE_REGION "2")
    elseif("${region}" STREQUAL "raw")
        set(NEDCMAKE_TYPE "3")
        set(NEDCMAKE_REGION "0")
    else()
        message(FATAL_ERROR "gba_target_archive_dotcode unknown region \"${region}\": valid regions are \"original\", \"non-japan\", \"japan-plus\" and \"raw\")")
    endif()

    # Additional arguments
    if(ARGN)
        list(GET ARGN 0 NEDCMAKE_NAME)
        set(NEDCMAKE_ARGS "-region" "${NEDCMAKE_REGION}" "-type" "${NEDCMAKE_TYPE}" "-bmp" "-name" "${NEDCMAKE_NAME}")
    else()
        set(NEDCMAKE_ARGS "-region" "${NEDCMAKE_REGION}" "-type" "${NEDCMAKE_TYPE}" "-bmp")
    endif()

    add_custom_command(TARGET ${target}
        POST_BUILD
        COMMAND "${GBA_TOOLCHAIN_NEDCMAKE}" -i "${input}" -o "${OUTPUT_FILE_WLE}" ${NEDCMAKE_ARGS}
        COMMENT "dotcode \"${input}\" -> \"${OUTPUT_FILE_WLE}-##.bmp\""
        BYPRODUCTS "${OUTPUT_FILE_WLE}-01.bmp" "${OUTPUT_FILE_WLE}-02.bmp" "${OUTPUT_FILE_WLE}-03.bmp"
            "${OUTPUT_FILE_WLE}-04.bmp" "${OUTPUT_FILE_WLE}-05.bmp" "${OUTPUT_FILE_WLE}-06.bmp"
            "${OUTPUT_FILE_WLE}-07.bmp" "${OUTPUT_FILE_WLE}-08.bmp" "${OUTPUT_FILE_WLE}-09.bmp"
            "${OUTPUT_FILE_WLE}-10.bmp" "${OUTPUT_FILE_WLE}-11.bmp" "${OUTPUT_FILE_WLE}-12.bmp"
    )
endfunction()
