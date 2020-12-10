#ifndef GBAXX_IO_REGISTERS_HPP
#define GBAXX_IO_REGISTERS_HPP

#include <gba/interrupt/flags.hpp>
#include <gba/keypad/keys.hpp>
#include <gba/video/display_control.hpp>
#include <gba/video/display_status.hpp>

namespace gba {
namespace io {

using display_control = gba::iomemmap<gba::display_control, 0x4000000>;
using display_status = gba::iomemmap<gba::display_status, 0x4000004>;
using vertical_count = gba::imemmap<uint16, 0x4000006>;

using key_status = gba::imemmap<gba::key_status, 0x4000130>;
using key_control = gba::imemmap<gba::key_control, 0x4000132>;

using interrupt_flag_enable = gba::iomemmap<irq::flags, 0x4000200>;
using interrupt_flag_requested = gba::imemmap<irq::flags, 0x4000202>;
using interrupt_flag_acknowledge = gba::omemmap<irq::flags, 0x4000202>;
using interrupt_master_enable = gba::iomemmap<bool, 0x4000208>;

} // io
} // gba

#endif // define GBAXX_IO_REGISTERS_HPP
