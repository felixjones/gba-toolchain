include(FetchContent)

if(EXISTS "${CMAKE_SYSTEM_LIBRARY_PATH}/agbabi/CMakeLists.txt" OR EXISTS "${CMAKE_BINARY_DIR}/lib/agbabi/CMakeLists.txt")
    add_subdirectory("${CMAKE_SYSTEM_LIBRARY_PATH}/agbabi" "${CMAKE_BINARY_DIR}/lib/agbabi" EXCLUDE_FROM_ALL)
else()
    find_library(libagbabi agbabi PATHS "${CMAKE_SYSTEM_LIBRARY_PATH}/agbabi" "${AGBABI_DIR}" PATH_SUFFIXES lib)

    if(NOT libagbabi)
        FetchContent_Declare(agbabi DOWNLOAD_EXTRACT_TIMESTAMP ON
            SOURCE_DIR "${CMAKE_SYSTEM_LIBRARY_PATH}/agbabi"
            GIT_REPOSITORY "https://github.com/felixjones/agbabi.git"
            GIT_TAG "main"
        )

        FetchContent_MakeAvailable(agbabi)
    else()
        add_library(agbabi STATIC IMPORTED)
        set_property(TARGET agbabi PROPERTY IMPORTED_LOCATION "${libagbabi}")

        get_filename_component(INCLUDE_PATH "${libagbabi}" DIRECTORY)
        get_filename_component(INCLUDE_PATH "${INCLUDE_PATH}" DIRECTORY)
        target_include_directories(agbabi INTERFACE "${INCLUDE_PATH}/include")

        unset(libagbabi CACHE)
    endif()
endif()
