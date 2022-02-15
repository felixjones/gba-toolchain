/*
===============================================================================

 Raycaster host tool

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_THREAD_LOCALS
#include "stb_image.h"

#include <stdint.h>
#include <stdio.h>

#define TEX_SIZE 64
#define NUM_CHANNELS 4

static uint16_t rgb24_to_bgr555(uint8_t red, uint8_t green, uint8_t blue);
static uint8_t palette_index(uint16_t color, uint16_t* palette, int* palLen);

typedef struct {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
    uint8_t alpha;
} color_type;

int main(int argc, char* argv[]) {
    if (argc < 2) {
        printf("Missing input argument");
        return 1;
    }

    int width, height, components;
    color_type* data = (color_type*) stbi_load(argv[1], &width, &height, &components, NUM_CHANNELS);
    if (!data) {
        printf("Failed to load %s", argv[1]);
        return 1;
    }

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

    FILE* binaryFile;
    if (fopen_s(&binaryFile, path, "wb")) {
        printf("Failed to open %s", path);
        return 1;
    }

    int palLen = 0;
    uint16_t palette[256] = {0};

    int numShades = height / TEX_SIZE;
    int numTextures = width / TEX_SIZE;
    for (int i = 0; i < numTextures; ++i) {
        for (int j = 0; j < numShades; ++j) {
            const color_type* texStart = &data[(j * width * TEX_SIZE) + (i * TEX_SIZE)];
            for (int x = 0; x < TEX_SIZE; ++x) {
                for (int y = 0; y < TEX_SIZE; ++y) {
                    const color_type color8888 = texStart[(y * width) + x];
                    const uint16_t color555 = rgb24_to_bgr555(color8888.red, color8888.green, color8888.blue);

                    const uint8_t idx = palette_index(color555, palette, &palLen);
                    fwrite(&idx, sizeof(idx), 1, binaryFile);
                }
            }
        }
    }

    fclose(binaryFile);

    // Replace extension with .pal
    strncpy(path, argv[1], sizeof(path));
    ext = path + sizeof(path) - 3;
    while (ext > path) {
        if (*ext == '.') {
            ext[1] = 'p';
            ext[2] = 'a';
            ext[3] = 'l';
            break;
        }
        ext--;
    }

    FILE* paletteFile;
    if (fopen_s(&paletteFile, path, "wb")) {
        printf("Failed to open %s", path);
        return 1;
    }

    fwrite(palette, sizeof(palette), 1, paletteFile);

    fclose(paletteFile);

    stbi_image_free(data);
    return 0;
}

static uint16_t rgb24_to_bgr555(uint8_t red, uint8_t green, uint8_t blue) {
    return ( red & 0xf8 ) >> 3 | ( green & 0xf8 ) << 2 | ( blue & 0xf8 ) << 7 | ( green & 0x04 ) << 13;
}

static uint8_t palette_index(uint16_t color, uint16_t* palette, int* palLen) {
    const int lastIdx = *palLen;
    for (uint8_t i = 0; i < lastIdx; ++i) {
        if (palette[i] == color) {
            return i;
        }
    }

    if (lastIdx >= 256) {
        return 0;
    }

    palette[lastIdx] = color;
    *palLen += 1;
    return lastIdx;
}
