void render() {
    int t = 0, t3 = 0, t5 = 0;
    while (true) {
        for (int y = 0; y < 160; ++y) {
            for (int x = 0; x < 240; ++x) {
                ((unsigned short*) 0x06000000)[x + y * 240] =
                        ((((x & y) + t) & 0x1F) << 10) |
                        ((((x & y) + t3) & 0x1F) << 5) |
                        ((((x & y) + t5) & 0x1F));
            }
        }
        ++t;
        t3 += 3;
        t5 += 5;
    }
}
