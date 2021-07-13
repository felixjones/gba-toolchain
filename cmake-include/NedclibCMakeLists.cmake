cmake_minimum_required(VERSION 3.0)

file(GLOB NEDCLIB_SRC "src/lib/*.cpp" "src/lib/rawbin/*.cpp" "src/lib/rawbmp/*.cpp" "src/lib/vpk/*.cpp")
foreach(file ${NEDCLIB_SRC})
    # Nedclib uses malloc.h, which is replaced by stdlib.h
    file(READ ${file} filedata)
    string(REGEX REPLACE "malloc.h" "stdlib.h" filedata "${filedata}")
    file(WRITE ${file} "${filedata}")
endforeach()

project(nedcmake CXX)
add_executable(nedcmake "src/nedcmake.cpp" ${NEDCLIB_SRC})
target_include_directories(nedcmake PRIVATE "src/lib/" "src/lib/rawbin" "src/lib/rawbmp" "src/lib/vpk")
