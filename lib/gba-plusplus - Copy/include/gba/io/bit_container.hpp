#ifndef GBAXX_IO_BIT_CONTAINER_HPP
#define GBAXX_IO_BIT_CONTAINER_HPP

#if !defined( __has_builtin )
#define __has_builtin( x )  0
#endif

#if __cpp_lib_bit_cast
#include <bit>
#endif

#if __cpp_lib_bit_cast || __has_builtin( __builtin_bit_cast )
#define gbaxx_bit_container_constexpr constexpr
#else
#define gbaxx_bit_container_constexpr
#endif

#include <gba/types/int_type.hpp>

namespace gba {

template <typename Type, unsigned Longs = sizeof( Type ) / 4, unsigned Shorts = ( sizeof( Type ) - ( Longs * 4 ) ) / 2, unsigned Bytes = sizeof( Type ) - ( Longs * 4 ) - ( Shorts * 2 )>
struct bit_container;

template <typename Type>
struct bit_container<Type, 0, 0, 1> {
    using type = uint8;
};

template <typename Type>
struct bit_container<Type, 0, 1, 0> {
    using type = uint16;
};

template <typename Type>
struct bit_container<Type, 1, 0, 0> {
    using type = uint32;
};

template <typename Type>
[[nodiscard]]
gbaxx_bit_container_constexpr auto to_bit_container( const Type& type ) noexcept -> typename std::enable_if<std::is_trivially_copyable<Type>::value, typename bit_container<Type>::type>::type {
#if __cpp_lib_bit_cast
    return std::bit_cast<typename bit_container<Type>::type>( type );
#elif __has_builtin( __builtin_bit_cast )
    return __builtin_bit_cast( typename bit_container<Type>::type, type );
#else
    return *reinterpret_cast<const typename bit_container<Type>::type *>( &type );
#endif
}

template <typename Type>
[[nodiscard]]
gbaxx_bit_container_constexpr auto from_bit_container( const volatile typename bit_container<Type>::type& container ) noexcept -> typename std::enable_if<std::is_trivially_copyable<Type>::value, Type>::type {
    const auto data = container;
#if __cpp_lib_bit_cast
    return std::bit_cast<Type>( data );
#elif __has_builtin( __builtin_bit_cast )
    return __builtin_bit_cast( Type, data );
#else
    return *reinterpret_cast<const Type *>( &data );
#endif
}

} // gba

#undef gbaxx_bit_container_constexpr

#endif // define GBAXX_IO_BIT_CONTAINER_HPP
