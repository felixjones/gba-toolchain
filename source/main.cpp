#include <gba/gba.hpp>

#define EVER ;;

using namespace gba;

[[gnu::target( "arm" ), gnu::section( ".iwram" )]]
static void vblank_handler() {
	static int t = 0;

	for ( int x = 0; x < 240; x++ ) {
		for ( int y = 0; y < 160; y++ ) {
			( ( volatile unsigned short * )0x06000000)[x + y * 240] = 
				( ( ( ( x & y ) + t ) & 0x1F ) << 10 ) | 
				( ( ( ( x & y ) + t * 3 ) & 0x1F ) << 5 ) |
				( ( ( ( x & y ) + t * 5 ) & 0x1F ) << 0 );
		}
	}
	t++;
}

[[gnu::section( ".iwram" )]]
static constexpr auto irq_handler = jump_table( interrupt_condition { 0x1, vblank_handler } );

int main(int argc, char* argv[]) {
	interrupt_handler::set( irq_handler );

	io::display_control::write( display_control::make( []( display_control& v ) {
		v.mode = 3;
		v.background_layer2 = true;
	} ) );

	io::display_status::write( display_status::make( []( display_status& v ) {
		v.emit_vblank = true;
	} ) );

	io::interrupt_mask_enable::write( interrupt::make( []( interrupt& v ) {
		v.vblank = true;
	} ) );

	io::interrupt_master_enable::write( true );

	for ( EVER ) {
		bios::vblank_intr_wait();
	}

	return 0;
}
