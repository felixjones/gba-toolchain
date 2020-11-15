#include "toolbox.hpp"

int main( int argc, char * argv[] ) {
    reg::dispcnt_set( display_control().mode( 3 ).background( 2 ) );

    mode<3>::plot( 120, 80, rgb15::make<31, 0, 0>() ); // Red
    mode<3>::plot( 136, 80, rgb15::make<0, 31, 0>() ); // Green
    mode<3>::plot( 120, 96, rgb15::make<0, 0, 31>() ); // Blue

    while ( true ) {}

    return 0;
}
