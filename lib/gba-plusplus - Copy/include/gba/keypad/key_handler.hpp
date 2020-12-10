#ifndef GBAXX_KEYPAD_KEY_HANDLER_HPP
#define GBAXX_KEYPAD_KEY_HANDLER_HPP

#include <gba/io/memmap.hpp>
#include <gba/keypad/keys.hpp>
#include <gba/types/int_type.hpp>

namespace gba {
namespace io {

template <class ReadSource>
class key_handler {
    static_assert( std::is_same_v<gba::key_status, typename ReadSource::type>, "key_handler requires key_status source" );
public:
    constexpr key_handler() noexcept : m_keys { 0x3ff }, m_xor { 0 } {}

    auto& poll() noexcept {
        const uint32 keys = imemmap<uint16, ReadSource::address>::read();
        m_xor = m_keys ^ keys;
        m_keys = keys;
        return *this;
    }

    [[nodiscard]]
    constexpr int axis_x() const noexcept {
        return -( ( m_keys & key::left.data ) == 0 ) + ( ( m_keys & key::right.data ) == 0 );
    }

    [[nodiscard]]
    constexpr int axis_y() const noexcept {
        return -( ( m_keys & key::up.data ) == 0 ) + ( ( m_keys & key::down.data ) == 0 );
    }

    [[nodiscard]]
    constexpr bool is_down( key_mask mask ) const noexcept {
        return ( m_keys & mask.data ) == 0;
    }

    [[nodiscard]]
    constexpr bool is_up( key_mask mask ) const noexcept {
        return ( m_keys & mask.data ) != 0;
    }

    [[nodiscard]]
    constexpr bool is_switched( key_mask mask ) const noexcept {
        return ( m_xor & mask.data ) == mask.data;
    }

    [[nodiscard]]
    constexpr bool is_pressed( key_mask mask ) const noexcept {
        return ( m_xor & mask.data ) == mask.data;
    }

    [[nodiscard]]
    constexpr bool is_switched_down( key_mask mask ) const noexcept {
        return is_switched( mask ) && is_down( mask );
    }

    [[nodiscard]]
    constexpr bool is_switched_up( key_mask mask ) const noexcept {
        return is_switched( mask ) && is_up( mask );
    }

    [[nodiscard]]
    constexpr bool any_down( key_mask mask ) const noexcept {
        return ( m_keys & mask.data ) != mask.data;
    }

    [[nodiscard]]
    constexpr bool any_up( key_mask mask ) const noexcept {
        return ( m_keys & mask.data ) == mask.data;
    }

    [[nodiscard]]
    constexpr bool any_switched( key_mask mask ) const noexcept {
        return ( m_xor & mask.data ) != 0;
    }

    [[nodiscard]]
    constexpr bool any_switched_down( key_mask mask ) const noexcept {
        return ( m_keys & m_xor & mask.data ) != ( m_xor & mask.data );
    }

    [[nodiscard]]
    constexpr bool any_switched_up( key_mask mask ) const noexcept {
        return ( m_keys & m_xor & mask.data ) != 0;
    }

    [[nodiscard]]
    constexpr bool only_down( key_mask mask ) const noexcept {
        return ( ~m_keys & 0x3ff ) == mask.data;
    }

    [[nodiscard]]
    constexpr bool only_up( key_mask mask ) const noexcept {
        return m_keys == mask.data;
    }

    [[nodiscard]]
    constexpr bool only_switched( key_mask mask ) const noexcept {
        return m_xor == mask.data;
    }

    [[nodiscard]]
    constexpr bool only_switched_down( key_mask mask ) const noexcept {
        return only_switched( mask ) && only_down( mask );
    }

    [[nodiscard]]
    constexpr bool only_switched_up( key_mask mask ) const noexcept {
        return only_switched( mask ) && only_up( mask );
    }

protected:
    uint32 m_keys;
    uint32 m_xor;

};

static_assert( sizeof( key_handler<imemmap<gba::key_status, 0>> ) == 8, "key_handler must be tightly packed" );

} // io
} // gba

#endif // define GBAXX_KEYPAD_KEY_HANDLER_HPP
