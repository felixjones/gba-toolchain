#include "camera.hpp"

#include <seven/prelude.h>

#include "asset_manager.hpp"

camera_type::camera_type(fixed_type startX, fixed_type startY, std::int32_t startAngle) noexcept : x { startX }, y { startY }, angle { startAngle } {
    dirX = fixed_type::from_raw(__agbabi_sin(angle + 0x2000) >> (29 - fixed_type::exponent));
    dirY = fixed_type::from_raw(__agbabi_sin(angle) >> (29 - fixed_type::exponent));
}

void camera_type::update() {
    const auto axisX = inputAxisX();
    if (axisX) {
        angle -= axisX * turn_speed;
        dirX = fixed_type::from_raw(__agbabi_sin(angle + 0x2000) >> (29 - fixed_type::exponent));
        dirY = fixed_type::from_raw(__agbabi_sin(angle) >> (29 - fixed_type::exponent));
    }

    const auto axisY = inputAxisY();
    const auto axisLR = inputAxisLR();
    if (axisY || axisLR) {
        const auto forward = move_speed * axisY;
        const auto strafe = strafe_speed * axisLR;

        x -= dirX * forward;
        x += dirY * strafe;

        y -= dirY * forward;
        y -= dirX * strafe;
    }
}
