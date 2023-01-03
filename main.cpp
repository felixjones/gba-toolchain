[[gnu::section(".cart.backup"), maybe_unused]]
const char save_string[] = "FLASH512_Vnnn";

#include <vector>
#include "test.hpp"

int main() {
    auto res = test::multiply(3, 4);

    auto a = std::vector<int>{};
    a.push_back(res);
}
