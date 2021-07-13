#include <array>

#include <gba/gba.hpp>
#include <gba/ext/agbabi.hpp> // Implicitly initializes IRQ handler

using namespace gba;

struct color_type {
    uint16 red : 5, green : 5, blue : 5, : 1;
};

static constexpr auto background_colors = std::array<color_type, 6> {
    color_type { .red = 31 },
    color_type { .red = 31, .green = 31 },
    color_type { .green = 31 },
    color_type { .green = 31, .blue = 31 },
    color_type { .blue = 31 },
    color_type { .red = 31, .blue = 31 }
};

int main( int argc, char * argv[] ) {
    reg::dispcnt::write( io::mode<0>::display_control().set_layer_background_0( true ) );

    reg::dispstat::write( display_status { .vblank_irq = true } );
    reg::ie::write( interrupt_mask { .vblank = true } );
    reg::ime::emplace( true );

    allocator::palette palette;
    auto backgroundColor = palette.allocate_background( 1 );
    backgroundColor.data( sizeof( color_type ), &background_colors[0] );

    int index = 0;
    io::keypad_manager keypad;

    while ( true ) {
        keypad.poll();

        bios::vblank_intr_wait();

        if ( keypad.any_switched_down( key_mask::make( key::up, key::down ) ) ) {
            index += keypad.axis_y();
            backgroundColor.data( sizeof( color_type ), &background_colors[index % background_colors.size()] );
        }
    }

    __builtin_unreachable();
}
