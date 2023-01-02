[[gnu::section(".cart.backup"), maybe_unused]]
const char save_string[] = "FLASH512_Vnnn";

#include <vector>

int main() {
    auto a = std::vector<int>{};
    a.emplace_back(54);
}
