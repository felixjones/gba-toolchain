#include "test.hpp"

int test::multiply(int a, int b) {
    int acc = 0;
    while (b--) {
        acc += a;
    }
    return acc;
}
