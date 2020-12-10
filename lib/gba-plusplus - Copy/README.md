# gba++

Modern Header-only C++ library for Game Boy Advance

# Status

This library is currently in the design & implementation phase.    
The first version, `0.0.1`, will be considered ready when we are functionally equivalent to [Tonclib](https://www.coranac.com/man/tonclib/modules.htm).

# Example style

Note: This is not functioning code.

```C++
#include <gba/gba.hpp>

using namespace gba;

int main( int argc, char * argv[] ) {
	interrupt_handler::set( nullptr ); // gba-toolchain empty IRQ handler, can be replaced with libgba/tonclib IRQ
	
	io::display_status::write( display_status { .emit_vblank = true } );
	io::interrupt_mask_enable::write( interrupt { .vblank = true } );
	io::interrupt_master_enable::write( true );

	while ( true ) {
		const auto keys = key_state( io::key_status::read() );
		if ( keys.button_a() ) {
			// Do something
		}
		
		bios::vblank_intr_wait();
	}
	
	return 0;
}
```

# Philosophy

Where possible, try to keep some compatibility with [libgba](https://github.com/devkitPro/libgba) and [Tonclib](https://www.coranac.com/man/tonclib/main.htm).

The user/toolchain manages memory (no static EWRAM/IWRAM allocations).

Interfaces to memory mapped types do not have state. Direct changes to memory should always be reflected in gba++ types.

Not a game engine.

No "tools". Just code.

STL used where it makes "perfect" sense.

Do as much as possible at compile-time.

Cool things are separate library projects (SRAM, SD file system, RTC time, dynamic libraries, Nitro types). 

Some helpful, optional utilities (VRAM allocators, general allocators, perspective 3D matrices).

Explicit API, functions and types should be understandable in terms of GBA features (80 column IDEs are not a concern).

Do not stop the user from doing what they explicitly ask (addressing VRAM as Mode 3 whilst in Mode 0 should be possible).

The user decides if a header is compiled as ARM or Thumb.

# Code style

Pretty much [Boost style](https://github.com/boostorg/geometry/wiki/Guidelines-for-Developers) but without the concern for 80 column IDEs.

Everything is within a `gba::` namespace.

Use gba++ types `gba::int16 gba::uint16` and keep volatile as a separate keyword.

# What License?

zlib going forward.
