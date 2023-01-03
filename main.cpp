void render();

int main() {
    *(unsigned int*)0x04000000 = 0x0403;
    render();
}
