if(PALETTE)
    foreach(INPUT ${INPUTS})
        get_filename_component(OUTPUT "${INPUT}" NAME_WE)
        execute_process(COMMAND "${PROGRAM}" palette
            --in-image "${INPUT}"
            --out-data "${PREFIX}${OUTPUT}${SUFFIX}"
            --mode gba
            ${PARAMS}
        )
    endforeach()
endif()

if(TILES)
    foreach(INPUT ${INPUTS})
        get_filename_component(OUTPUT "${INPUT}" NAME_WE)
        set(INPUT_PALETTE "${PREFIX_PALETTE}${OUTPUT}${SUFFIX_PALETTE}")
        execute_process(COMMAND "${PROGRAM}" tiles
            --in-image "${INPUT}"
            --in-palette "${INPUT_PALETTE}"
            --out-data "${PREFIX}${OUTPUT}${SUFFIX}"
            --mode gba
            ${PARAMS}
        )
    endforeach()
endif()

if(MAP)
    foreach(INPUT ${INPUTS})
        get_filename_component(OUTPUT "${INPUT}" NAME_WE)
        set(INPUT_PALETTE "${PREFIX_PALETTE}${OUTPUT}${SUFFIX_PALETTE}")
        set(INPUT_TILES "${PREFIX_TILES}${OUTPUT}${SUFFIX_TILES}")
        execute_process(COMMAND "${PROGRAM}" map
            --in-image "${INPUT}"
            --in-palette "${INPUT_PALETTE}"
            --in-tiles "${INPUT_TILES}"
            --out-data "${PREFIX}${OUTPUT}${SUFFIX}"
            --mode gba
            ${PARAMS}
        )
    endforeach()
endif()
