#include <cstdlib>

#define EVER ;;

int main(int argc, char* argv[]) {
	auto data = (volatile unsigned short*)std::malloc(sizeof(short));
	*(volatile unsigned int*)0x04000000 = 0x0403;

	int t = 0;
	for (EVER) {
		int x, y;
		for (x = 0; x < 240; ++x) {
			for (y = 0; y < 160; ++y) {
				*data = ((((x & y) + t) & 0x1F) << 10) | ((((x & y) + t * 3) & 0x1F) << 5) | ((((x & y) + t * 5) & 0x1F) << 0);
				((volatile unsigned short*)0x06000000)[x + y * 240] = *data;
			}
		}
		++t;
	}
	return 0;
}
