#ifndef GBAXX_VIDEO_OBJECT_ATTRIBUTE_HPP
#define GBAXX_VIDEO_OBJECT_ATTRIBUTE_HPP


#include <gba/io/bufmap.hpp>
#include <gba/types/fixed_point_make.hpp>
#include <gba/types/int_type.hpp>

namespace gba {
namespace object {

enum class graphics_mode : uint16 {
    normal = 0,
    blend = 1,
    window = 2
};

enum class color_mode : uint16 {
    bpp4 = 0,
    bbp8 = 1
};

enum class shape : uint16 {
    square = 0,
    wide = 1,
    tall = 2
};

} // object

struct [[gnu::aligned( 8 )]] object_attribute {
    uint16 y : 8;
    bool affine : 1,
            hidden_OR_double_size : 1;
    object::graphics_mode graphics_mode : 2;
    bool mosaic : 1;
    object::color_mode color_mode : 1;
    object::shape shape : 2;

    uint16 x : 9,
        yflip_xflip_OR_affine_index : 5,
        size : 2;

    uint16 tile_index : 10,
        priority : 2,
        palette_bank : 4;

    make_fixed<7, 8> matrix;
};

static_assert( sizeof( object_attribute ) == 8, "object_attribute must be tightly packed" );

struct object_affine : object_attribute {
    constexpr object_affine() noexcept : object_attribute {
        0, true, false, object::graphics_mode::normal, false, object::color_mode::bpp4, object::shape::square,
        0, 0, 0,
        0, 0, 0,
        0
    } {}

    constexpr auto& y( int value ) noexcept {
        object_attribute::y = value;
        return *this;
    }

    constexpr auto& double_size( bool value ) noexcept {
        object_attribute::hidden_OR_double_size = value;
        return *this;
    }

    constexpr auto& graphics_mode( object::graphics_mode value ) noexcept {
        object_attribute::graphics_mode = value;
        return *this;
    }

    constexpr auto& mosaic( bool value ) noexcept {
        object_attribute::mosaic = value;
        return *this;
    }

    constexpr auto& color_mode( object::color_mode value ) noexcept {
        object_attribute::color_mode = value;
        return *this;
    }

    constexpr auto& shape( object::shape value ) noexcept {
        object_attribute::shape = value;
        return *this;
    }

    constexpr auto& x( int value ) noexcept {
        object_attribute::x = value;
        return *this;
    }

    constexpr auto& affine_index( int value ) noexcept {
        object_attribute::yflip_xflip_OR_affine_index = value;
        return *this;
    }

    constexpr auto& size( int value ) noexcept {
        object_attribute::size = value;
        return *this;
    }

    constexpr auto& tile_index( int value ) noexcept {
        object_attribute::tile_index = value;
        return *this;
    }

    constexpr auto& priority( int value ) noexcept {
        object_attribute::priority = value;
        return *this;
    }

    constexpr auto& palette_bank( int value ) noexcept {
        object_attribute::palette_bank = value;
        return *this;
    }

protected:
    using object_attribute::affine;

};

static_assert( sizeof( object_affine ) == 8, "object_affine must be tightly packed" );

struct object_affine_group {
    class matrix_ref {
    public:
        constexpr matrix_ref( object_affine_group& owner ) noexcept : m_owner { owner } {}

        constexpr auto& operator[]( int i ) noexcept {
            return m_owner.data[i].matrix;
        }

    protected:
        object_affine_group& m_owner;

    };

    constexpr auto& operator[]( int i ) noexcept {
        return data[i];
    }

    constexpr auto matrix() noexcept {
        return matrix_ref( *this );
    }

protected:
    object_affine data[4];

};

static_assert( sizeof( object_affine_group ) == 32, "object_affine_group must be tightly packed" );

using object_attributes_affine_group = bufmap<0x7000000, object_affine_group, 32>;

} // gba

#endif // define GBAXX_VIDEO_OBJECT_ATTRIBUTE_HPP
