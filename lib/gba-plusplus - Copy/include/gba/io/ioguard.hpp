#ifndef GBAXX_IO_IOGUARD_HPP
#define GBAXX_IO_IOGUARD_HPP

namespace gba {

template <class IOMemmap>
class io_guard {
public:
    using value_type = typename IOMemmap::type;

    io_guard( const io_guard& ) = delete;
    io_guard& operator =( const io_guard& ) = delete;

    explicit io_guard() noexcept : m_data { IOMemmap::read() } {}

    ~io_guard() noexcept {
        IOMemmap::write( m_data );
    }

    io_guard& operator =( const value_type& value ) noexcept {
        m_data = value;
        return *this;
    }

    value_type& operator *() noexcept {
        return m_data;
    }

    value_type * operator ->() noexcept {
        return &m_data;
    }

protected:
    value_type  m_data;

};

} // gba

#endif // define GBAXX_IO_IOGUARD_HPP

/*
struct reference {
    [[gnu::always_inline]]
    reference& operator =( const Type& value ) noexcept {
        iomemmap::write( value );
        return *this;
    }

    [[gnu::always_inline]]
    reference& operator =( Type&& value ) noexcept {
        iomemmap::write( value );
        return *this;
    }

    [[gnu::always_inline]]
    volatile Type& operator *() noexcept {
        return *reinterpret_cast<volatile Type *>( iomemmap::address );
    }

    [[gnu::always_inline]]
    volatile Type * operator ->() noexcept {
        return reinterpret_cast<volatile Type *>( iomemmap::address );
    }
};
*/