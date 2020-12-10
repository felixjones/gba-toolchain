#ifndef GBAXX_VIDEO_PALETTE_HPP
#define GBAXX_VIDEO_PALETTE_HPP

#include <memory>

#include <gba/io/bufmap.hpp>
#include <gba/types/color.hpp>
#include <gba/types/int_type.hpp>

namespace gba {

/**
 *
 * @tparam PaletteDef
 */
template <typename PaletteDef>
struct palette : PaletteDef {
    using value_type = typename PaletteDef::value_type;
    using size_type = typename PaletteDef::size_type;
    using difference_type = typename PaletteDef::difference_type;
    using reference = typename PaletteDef::reference;
    using const_reference = typename PaletteDef::const_reference&;
    using pointer = typename PaletteDef::pointer&;
    using const_pointer = typename PaletteDef::const_pointer&;
    using iterator = typename PaletteDef::iterator;
    using const_iterator = typename PaletteDef::const_iterator;

    reference at( size_type pos ) noexcept {
        return PaletteDef::at( pos );
    }

    const_reference at( size_type pos ) const noexcept {
        return PaletteDef::at( pos );
    }

    reference operator []( size_type pos ) noexcept {
        return PaletteDef::at( pos );
    }

    const_reference operator []( size_type pos ) const noexcept {
        return PaletteDef::at( pos );
    }

    reference front() noexcept {
        return PaletteDef::front();
    }

    const_reference front() const noexcept {
        return PaletteDef::front();
    }

    reference back() noexcept {
        return PaletteDef::back();
    }

    const_reference back() const noexcept {
        return PaletteDef::back();
    }

    pointer data() noexcept {
        return PaletteDef::data();
    }

    const_pointer data() const noexcept {
        return PaletteDef::data();
    }

    iterator begin() noexcept {
        return PaletteDef::begin();
    }

    const_iterator cbegin() noexcept {
        return PaletteDef::cbegin();
    }

    iterator end() noexcept {
        return PaletteDef::end();
    }

    const_iterator cend() noexcept {
        return PaletteDef::end();
    }
};

using palette_background_8bpp = bufmap<0x5000000, color::rgb555, 256>;
using palette_object_8bpp = bufmap<0x5000200, color::rgb555, 256>;

using palette_background_4bpp = bufmap_banked<0x5000000, color::rgb555, 16>;
using palette_object_4bpp = bufmap_banked<0x5000200, color::rgb555, 16>;

} // gba

#endif // GBAXX_VIDEO_PALETTE_HPP
