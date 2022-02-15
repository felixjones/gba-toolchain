/*
===============================================================================

 Raycaster host tool

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAP_SIZE 24

int main(int argc, char* argv[]) {
    if (argc < 2) {
        printf("Missing input argument");
        return 1;
    }

    char binaryMap[MAP_SIZE * MAP_SIZE];

    FILE* textFile = fopen(argv[1], "r");
    if (!textFile) {
        printf("Failed to open %s", argv[1]);
        return 1;
    }

    int y = 0, x = 0;
    while (y < MAP_SIZE) {
        const char ch = fgetc(textFile);
        if (ch == '\r' || ch == '\n') {
            continue;
        }

        binaryMap[(y * MAP_SIZE) + x] = ch - '0';
        ++x;
        if (x == MAP_SIZE) {
            x = 0;
            ++y;
        }
    }

    fclose(textFile);

    // Create bin name
    // Replace extension with .bin
    char path[260];
    strncpy(path, argv[1], sizeof(path));
    char* ext = path + sizeof(path) - 3;
    while (ext > path) {
        if (*ext == '.') {
            ext[1] = 'b';
            ext[2] = 'i';
            ext[3] = 'n';
            break;
        }
        ext--;
    }

    FILE* binaryFile = fopen(path, "wb");
    if (!binaryFile) {
        printf("Failed to open %s", path);
        return 1;
    }

    fwrite(binaryMap, 1, MAP_SIZE * MAP_SIZE, binaryFile);

    fclose(binaryFile);
    return 0;
}
