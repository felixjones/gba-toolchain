#include <tonc.h>

void render() {
    int t = 0, t3 = 0, t5 = 0;
    while (true) {
        for (int y = 0; y < 160; ++y) {
            for (int x = 0; x < 240; ++x) {
                vid_mem[x + y * 240] = RGB15_SAFE(
                    (x & y) + t5,
                    (x & y) + t3,
                    (x & y) + t
                );
            }
        }
        ++t;
        t3 += 3;
        t5 += 5;
    }
}
