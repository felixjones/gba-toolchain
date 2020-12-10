#ifndef GBAXX_IO_BUFMAP_HPP
#define GBAXX_IO_BUFMAP_HPP

#include <gba/types/int_type.hpp>

namespace gba {

/**
 *
 * @tparam Address
 * @tparam Length
 */
template <unsigned Address, class ValueType, unsigned Length>
struct bufmap {
    using value_type = ValueType;
    using size_type = uint32;
    using difference_type = int32;
    using reference = value_type&;
    using const_reference = const value_type&;
    using pointer = value_type *;
    using const_pointer = const value_type *;

    /**
     *
     */
    class iterator {
    public:
        using iterator_category = std::forward_iterator_tag;

        using value_type = ValueType;
        using size_type = uint32;
        using difference_type = int32;
        using reference = value_type&;
        using const_reference = const value_type&;
        using pointer = value_type *;
        using const_pointer = const value_type *;

        constexpr explicit iterator( size_type pos ) noexcept : m_pos { pos } {}
        constexpr iterator( const iterator& other ) noexcept : m_pos { other.m_pos } {}

        bool operator ==( const iterator& other ) const noexcept {
            return m_pos == other.m_pos;
        }

        bool operator !=( const iterator& other ) const noexcept {
            return m_pos != other.m_pos;
        }

        reference operator *() noexcept {
            return at( m_pos );
        }

        pointer operator ->() noexcept {
            return data() + m_pos;
        }

        iterator& operator=( const iterator& other ) noexcept {
            m_pos = other.m_pos;
            return *this;
        }

        iterator operator ++( int ) noexcept {
            return iterator( m_pos++ );
        }

        iterator& operator ++() noexcept {
            ++m_pos;
            return *this;
        }

    protected:
        size_type m_pos;
    };

    /**
     *
     */
    class const_iterator {
    public:
        using iterator_category = std::forward_iterator_tag;

        using value_type = ValueType;
        using size_type = uint32;
        using difference_type = int32;
        using reference = value_type&;
        using const_reference = const value_type&;
        using pointer = value_type *;
        using const_pointer = const value_type *;

        constexpr explicit const_iterator( size_type pos ) noexcept : m_pos { pos } {}

        bool operator ==( const const_iterator& other ) const noexcept {
            return m_pos == other.m_pos;
        }

        bool operator !=( const const_iterator& other ) const noexcept {
            return m_pos != other.m_pos;
        }

        const_reference operator *() noexcept {
            return at( m_pos );
        }

        const_pointer operator ->() noexcept {
            return data() + m_pos;
        }

        const_iterator& operator=( const const_iterator& other ) noexcept {
            m_pos = other.m_pos;
            return *this;
        }

        const_iterator operator ++( int ) noexcept {
            return iterator( m_pos++ );
        }

        const_iterator& operator ++() noexcept {
            ++m_pos;
            return *this;
        }

    protected:
        size_type m_pos;
    };

    static reference at( size_type pos ) noexcept {
        return data()[pos];
    }

    static reference front() noexcept {
        return *data();
    }

    static reference back() noexcept {
        return at( Length - 1 );
    }

    static pointer data() noexcept {
        return std::launder( reinterpret_cast<pointer>( Address ) );
    }

    static iterator begin() noexcept {
        return iterator( 0 );
    }

    static const_iterator cbegin() noexcept {
        return const_iterator( 0 );
    }

    static iterator end() noexcept {
        return iterator( Length );
    }

    static const_iterator cend() noexcept {
        return const_iterator( Length );
    }
};

/**
 *
 * @tparam Address
 * @tparam ValueType
 * @tparam Length
 */
template <unsigned Address, class ValueType, unsigned Length>
struct bufmap_banked {
    using value_type = ValueType;
    using size_type = uint32;
    using difference_type = int32;
    using reference = value_type&;
    using const_reference = const value_type&;
    using pointer = value_type *;
    using const_pointer = const value_type *;

    /**
     *
     */
    class iterator {
    public:
        using iterator_category = std::forward_iterator_tag;

        using value_type = ValueType;
        using size_type = uint32;
        using difference_type = int32;
        using reference = value_type&;
        using const_reference = const value_type&;
        using pointer = value_type *;
        using const_pointer = const value_type *;

        constexpr explicit iterator( bufmap_banked& owner, size_type pos ) noexcept : m_owner { owner }, m_pos { pos } {}

        bool operator ==( const iterator& other ) const noexcept {
            return m_owner.bank == other.m_owner.bank && m_pos == other.m_pos;
        }

        bool operator !=( const iterator& other ) const noexcept {
            return m_owner.bank != other.m_owner.bank || m_pos != other.m_pos;
        }

        reference operator *() noexcept {
            return m_owner.at( m_pos );
        }

        pointer operator ->() noexcept {
            return m_owner.data() + m_pos;
        }

        iterator& operator=( const iterator& other ) noexcept {
            m_pos = other.m_pos;
            return *this;
        }

        iterator operator ++( int ) noexcept {
            return iterator( m_owner, m_pos++ );
        }

        iterator& operator ++() noexcept {
            ++m_pos;
            return *this;
        }

        iterator operator +( int i ) noexcept {
            return iterator( m_owner, m_pos + i );
        }

    protected:
        bufmap_banked& m_owner;
        size_type m_pos;
    };

    /**
     *
     */
    class const_iterator {
    public:
        using iterator_category = std::forward_iterator_tag;

        using value_type = ValueType;
        using size_type = uint32;
        using difference_type = int32;
        using reference = value_type&;
        using const_reference = const value_type&;
        using pointer = value_type *;
        using const_pointer = const value_type *;

        constexpr explicit const_iterator( const bufmap_banked& owner, size_type pos ) noexcept : m_owner { owner }, m_pos { pos } {}

        bool operator ==( const const_iterator& other ) const noexcept {
            return m_owner.bank == other.m_owner.bank && m_pos == other.m_pos;
        }

        bool operator !=( const const_iterator& other ) const noexcept {
            return m_owner.bank != other.m_owner.bank || m_pos != other.m_pos;
        }

        const_reference operator *() noexcept {
            return m_owner.at( m_pos );
        }

        const_pointer operator ->() noexcept {
            return m_owner.data() + m_pos;
        }

        const_iterator& operator=( const const_iterator& other ) noexcept {
            m_pos = other.m_pos;
            return *this;
        }

        const_iterator operator ++( int ) noexcept {
            return const_iterator( m_owner, m_pos++ );
        }

        const_iterator& operator ++() noexcept {
            ++m_pos;
            return *this;
        }

    protected:
        const bufmap_banked& m_owner;
        size_type m_pos;
    };

    constexpr explicit bufmap_banked( size_type b ) noexcept : bank { b } {}

    reference at( size_type pos ) noexcept {
        return data()[pos];
    }

    [[nodiscard]]
    const_reference at( size_type pos ) const noexcept {
        return data()[pos];
    }

    reference operator []( size_type pos ) noexcept {
        return at( pos );
    }

    [[nodiscard]]
    const_reference operator []( size_type pos ) const noexcept {
        return at( pos );
    }

    reference front() noexcept {
        return *data();
    }

    [[nodiscard]]
    const_reference front() const noexcept {
        return *data();
    }

    reference back() noexcept {
        return at( Length - 1 );
    }

    [[nodiscard]]
    const_reference back() const noexcept {
        return at( Length - 1 );
    }

    pointer data() noexcept {
        return std::launder( reinterpret_cast<pointer>( Address ) + ( bank * Length ) );
    }

    [[nodiscard]]
    const_pointer data() const noexcept {
        return std::launder( reinterpret_cast<pointer>( Address ) + ( bank * Length ) );
    }

    iterator begin() noexcept {
        return iterator( *this, 0 );
    }

    const_iterator cbegin() noexcept {
        return const_iterator( *this, 0 );
    }

    iterator end() noexcept {
        return iterator( *this, Length );
    }

    const_iterator cend() noexcept {
        return const_iterator( *this, Length );
    }

    size_type bank;
};

} // gba

#endif // define GBAXX_IO_BUFMAP_HPP
