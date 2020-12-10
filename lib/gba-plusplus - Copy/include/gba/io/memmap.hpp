#ifndef GBAXX_IO_MEMMAP_HPP
#define GBAXX_IO_MEMMAP_HPP

#include <type_traits>

#include <gba/io/bit_container.hpp>

namespace gba {

template <typename Type, unsigned Address>
class memmap {
public:
    using type = Type;
    static constexpr auto address = Address;
};

// Read only memory mapped
template <typename Type, unsigned Address, typename Void = void>
class imemmap;

template <typename Type, unsigned Address>
class imemmap<Type, Address, typename std::enable_if<std::is_fundamental<Type>::value>::type> : public memmap<Type, Address> {
public:
    [[nodiscard, gnu::always_inline]]
    static Type read() noexcept {
        return *reinterpret_cast<volatile const Type *>( Address );
    }
};

template <typename Type, unsigned Address>
class imemmap<Type, Address, typename std::enable_if<!std::is_fundamental<Type>::value>::type> : public memmap<Type, Address> {
    using container_type = typename bit_container<Type>::type;
public:
    [[nodiscard, gnu::always_inline]]
    static Type read() noexcept {
        return from_bit_container<Type>( *reinterpret_cast<const volatile container_type *>( Address ) );
    }
};

// Write only memory mapped
template <typename Type, unsigned Address, typename Void = void>
class omemmap;

template <typename Type, unsigned Address>
class omemmap<Type, Address, typename std::enable_if<std::is_fundamental<Type>::value>::type> : public memmap<Type, Address> {
public:
    [[gnu::always_inline]]
    static void write( const Type& value ) noexcept {
        *reinterpret_cast<volatile Type *>( Address ) = value;
    }
};

template <typename Type, unsigned Address>
class omemmap<Type, Address, typename std::enable_if<!std::is_fundamental<Type>::value>::type> : public memmap<Type, Address> {
    using container_type = typename bit_container<Type>::type;
public:
    [[gnu::always_inline]]
    static void write( const Type& value ) noexcept {
        *reinterpret_cast<volatile container_type *>( Address ) = to_bit_container( value );
    }

    [[gnu::always_inline]]
    static void write( Type&& value ) noexcept {
        *reinterpret_cast<volatile container_type *>( Address ) = to_bit_container( value );
    }
};

template <typename Type, unsigned Address>
class iomemmap : public imemmap<Type, Address>, public omemmap<Type, Address> {
};

} // gba

#endif // define GBAXX_IO_MEMMAP_HPP
