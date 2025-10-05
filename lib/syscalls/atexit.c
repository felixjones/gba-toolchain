/*
===============================================================================

 Copyright (C) 2025 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <stdlib.h>

struct __atexit_node {
    void (*dtor)(void*);
    void *obj;
    struct __atexit_node *next;
};

static struct __atexit_node* __atexit_head = 0;

int __aeabi_atexit(void* object, void(*destructor)(void*), void* dso) {
    struct __atexit_node* n = malloc(sizeof(struct __atexit_node));

    n->dtor = destructor;
    n->obj = object;
    n->next = __atexit_head;

    __atexit_head = n;
    return 0;
}

void __call_exitprocs(int code, void* dso) {
    while (__atexit_head) {
        struct __atexit_node* next = __atexit_head->next;
        __atexit_head->dtor(__atexit_head->obj);
        // Don't both freeing memory, we're exiting anyway
        __atexit_head = next;
    }
}
