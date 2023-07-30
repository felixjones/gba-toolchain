include("${CMAKE_CURRENT_LIST_DIR}/IHex.cmake")

# Returns a file intended for temporary storage
# Avoids overwriting existing files by appending a counter
function(maketmp outvar basename)
    get_filename_component(basename "${basename}" ABSOLUTE)
    if(NOT EXISTS "${basename}")
        set(${outvar} "${basename}" PARENT_SCOPE)
    endif()

    get_filename_component(dir "${basename}" DIRECTORY)
    get_filename_component(name "${basename}" NAME_WE)
    get_filename_component(ext "${basename}" EXT)

    string(RANDOM random)
    while(EXISTS "${dir}/${name}${random}${ext}")
        string(RANDOM random)
    endwhile()
    set(${outvar} "${dir}/${name}${random}${ext}" PARENT_SCOPE)
endfunction()

# Binary append function
function(binappend first)
    maketmp(tmp "${first}")
    get_filename_component(workingdir "${tmp}" DIRECTORY)

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E cat "${first}" "${ARGN}"
        WORKING_DIRECTORY "${workingdir}"
        OUTPUT_FILE "${tmp}"
    )
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E rename "${tmp}" "${first}"
        WORKING_DIRECTORY "${workingdir}"
    )
endfunction()

# Align function
function(binalign file align)
    if(${align} LESS_EQUAL 1)
        return()
    endif()
    get_filename_component(file "${file}" ABSOLUTE)

    file(SIZE "${file}" startbytes)
    math(EXPR endbytes "((${startbytes} + (${align} - 1)) / ${align}) * ${align}")
    math(EXPR padbytes "${endbytes} - ${startbytes}")

    maketmp(tmp "${file}")
    get_filename_component(workingdir "${tmp}" DIRECTORY)

    unset(padfile)

    if(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux" OR CMAKE_HOST_SYSTEM_NAME MATCHES "Darwin")
        execute_process(
            COMMAND dd bs=${padbytes} seek=1 "of=${tmp}" count=0
            WORKING_DIRECTORY "${workingdir}"
            OUTPUT_QUIET ERROR_QUIET
        )
        set(padfile "${tmp}")
    endif()

    if(NOT padfile AND CMAKE_HOST_SYSTEM_NAME MATCHES "Windows")
        find_program(CMAKE_FSUTIL_PROGRAM fsutil)
        if(CMAKE_FSUTIL_PROGRAM)
            execute_process(
                COMMAND "${CMAKE_FSUTIL_PROGRAM}" file createnew "${tmp}" ${padbytes}
                WORKING_DIRECTORY "${workingdir}"
                OUTPUT_QUIET ERROR_QUIET
            )
            set(padfile "${tmp}")
        endif()
    endif()

    if(NOT padfile)
        string(REPEAT "00" ${padbytes} zeroes)
        ihex(outputHex RECORD_LENGTH 0xff "${zeroes}")

        string(RANDOM ihexFile)
        while(EXISTS "${ihexFile}.hex")
            string(RANDOM ihexFile)
        endwhile()

        # Write ihex file and objcopy into output binary
        file(WRITE "${workingdir}/${ihexFile}.hex" "${outputHex}")
        execute_process(
            COMMAND "${CMAKE_OBJCOPY}" -I ihex "${ihexFile}.hex" -O binary "${tmp}"
            WORKING_DIRECTORY "${workingdir}"
        )
        file(REMOVE "${ihexFile}.hex")
        set(padfile "${tmp}")
    endif()

    binappend("${file}" "${padfile}")
    file(REMOVE "${padfile}")
endfunction()

# binconcat
function(binconcat align first)
    if(NOT ARGN)
        return() # Don't concat nothing
    endif()

    foreach(arg ${ARGN})
        binalign("${first}" ${align}) # Align to next boundary
        binappend("${first}" "${arg}") # Append next file
    endforeach()
endfunction()
