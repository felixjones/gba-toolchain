#ifndef GBAXX_KEYPAD_KEYS_HPP
#define GBAXX_KEYPAD_KEYS_HPP

namespace gba {

/**
 *
 */
struct key_status {
    bool button_a : 1,
            button_b : 1,
            select : 1,
            start : 1,
            right : 1,
            left : 1,
            up : 1,
            down : 1,
            button_r : 1,
            button_l : 1;
};

static_assert( sizeof( key_status ) == 2, "key_status must be tightly packed" );

/**
 *
 */
struct key_control {
    bool button_a : 1,
            button_b : 1,
            select : 1,
            start : 1,
            right : 1,
            left : 1,
            up : 1,
            down : 1,
            button_r : 1,
            button_l : 1,
            : 4,
            key_irq : 1,
            irq_operator_and : 1;
};

static_assert( sizeof( key_control ) == 2, "key_control must be tightly packed" );

/**
 *
 */
struct key_mask {
    uint32 data;
};

[[nodiscard]]
constexpr key_mask operator |( const key_mask& lhs, const key_mask& rhs ) noexcept {
    return key_mask { lhs.data | rhs.data };
}

static_assert( sizeof( key_mask ) == 4, "key_mask must be tightly packed" );

namespace key {
namespace {

constexpr auto button_a = key_mask { 0x1 << 0 };
constexpr auto button_b = key_mask { 0x1 << 1 };
constexpr auto select = key_mask { 0x1 << 2 };
constexpr auto start = key_mask { 0x1 << 3 };
constexpr auto right = key_mask { 0x1 << 4 };
constexpr auto left = key_mask { 0x1 << 5 };
constexpr auto up = key_mask { 0x1 << 6 };
constexpr auto down = key_mask { 0x1 << 7 };
constexpr auto button_r = key_mask { 0x1 << 8 };
constexpr auto button_l = key_mask { 0x1 << 9 };

}
} // key
} // gba

#endif // define GBAXX_KEYPAD_KEYS_HPP
