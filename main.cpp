[[gnu::section(".cart.backup"), maybe_unused]]
const char save_string[] = "FLASH512_Vnnn";

[[maybe_unused]]
static int bss_hopefully = 0;

int main() {
    bss_hopefully = 54;
}
