#include <gba/gba.hpp>

#include <cmath>

#define EVER ;;

using namespace gba;

[[gnu::section( ".iwram.data" )]]
fixed_point<int, 6> d;

[[gnu::target( "arm" ), gnu::section( ".iwram" )]]
static void vblank( interrupt i ) {
	if ( i.vblank ) {
		d.data()++;
		const auto cd = math::cos( d );
		const auto sd = math::sin( d );
		io::background2_matrix::write(
			io::background2_matrix::type(
				cd, -sd,
				sd, cd
			)
			*
			io::background2_matrix::type(
				cd
			)
		);
		io::background2_offset::write( { 120, 80 } );
	}
}

int main(int argc, char* argv[]) {
	interrupt_handler::set( vblank );

	io::display_control::write( make<display_control>( []( auto& v ) {
		v.mode = 3;
		v.background_layer2 = true;
	} ) );

	io::display_status::write( make<display_status>( []( auto& v ) {
		v.emit_vblank = true;
	} ) );

	io::interrupt_mask_enable::write( make<interrupt>( []( auto& v ) {
		v.vblank = true;
	} ) );

	io::interrupt_master_enable::write( true );

	int t = 0;
	for ( EVER ) {
		for ( int x = 0; x < 240; x++ ) {
			for ( int y = 0; y < 160; y++ ) {
				( ( volatile unsigned short * )0x06000000)[x + y * 240] = 
					( ( ( ( x & y ) + t ) & 0x1F ) << 10 ) | 
					( ( ( ( x & y ) + t * 3 ) & 0x1F ) << 5 ) |
					( ( ( ( x & y ) + t * 5 ) & 0x1F ) << 0 );
			}
		}

		t++;

		bios::vblank_intr_wait();
	}

	return 0;
}
