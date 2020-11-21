#include <stdarg.h>
#include <sys/ucontext.h>

#define REGISTER_ARGS   ( 4 )

void __agbabi_makecontext( struct ucontext_t *, void ( * )( void ), int, ... ) __attribute__((section(".iwram")));
void __agbabi_ctx_start();

void __agbabi_makecontext( struct ucontext_t * ucp, void ( * func )( void ), int argc, ... ) {
    long unsigned int * funcstack = ( long unsigned int * ) ( ucp->uc_stack.ss_sp + ucp->uc_stack.ss_size );

    if ( argc > REGISTER_ARGS ) {
        funcstack -= ( argc - REGISTER_ARGS );
    }

    ucp->uc_mcontext.arm_sp = ( long unsigned int ) funcstack;
    ucp->uc_mcontext.arm_lr = ( long unsigned int ) __agbabi_ctx_start;
    ucp->uc_mcontext.arm_r4 = ( long unsigned int ) func;
    ucp->uc_mcontext.arm_r5 = ( long unsigned int ) ucp->uc_link;

    va_list vl;
    va_start( vl, argc );

    long unsigned int reg;
    long unsigned int * regptr = &ucp->uc_mcontext.arm_r0;

    for ( reg = 0; reg < argc && reg < REGISTER_ARGS; ++reg ) {
        *regptr++ = va_arg( vl, long unsigned int );
    }

    for ( ; reg < argc; ++reg ) {
        *funcstack++ = va_arg( vl, long unsigned int );
    }

    va_end( vl );
}
