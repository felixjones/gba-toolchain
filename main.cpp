#include <cmath>
#include <numbers>

#include <agbabi.h>
#include <gcem.hpp>
#include <seven/hw/video.h>
#include <seven/hw/video/bg_bitmap.h>

#include "lut_generator.hpp"
#include "fixed.hpp"

static constexpr auto fine_angles = 8192;
static constexpr auto fine_angles_2 = fine_angles / 2;
static constexpr auto fine_angles_4 = fine_angles / 4;
static constexpr auto fine_angles_8 = fine_angles / 8;

static constexpr auto fine_angle_tangent = lut::make<fine_angles_2>([](std::size_t i) {
    return gcem::tan((i - (fine_angles / 4.0) + 0.5) * std::numbers::pi_v<double> * 2.0 / fine_angles);
});

static constexpr auto screen_width = MODE3_WIDTH;

static constexpr auto focal_length = (screen_width / 2.0f) / fine_angle_tangent[fine_angles_4 + fine_angles_8];

static constexpr auto view_angle_to_x = lut::make<fine_angles_2>([](std::size_t i) {
    if (fine_angle_tangent[i] > 2.0f) {
        return fixed(-1);
    } else if (fine_angle_tangent[i] < -2.0f) {
        return fixed(screen_width);
    } else {
        auto t = fixed(fine_angle_tangent[i] * focal_length);
        t = (screen_width / 2) - t + 0.99999999999999999999999;

        if (t < -1) {
            return fixed(-1);
        } else if (t > screen_width) {
            return fixed(screen_width);
        }

        return t;
    }
});

static constexpr auto angle_90 = angle(std::numbers::pi_v<double> / 2.0);

static constexpr auto x_to_view_angle = lut::make<screen_width>([](std::size_t i) {
    auto x = std::size_t{};
    while (int(view_angle_to_x[x]) > int(i)) {
        ++x;
    }
    return angle::from_int<13>(x) - angle_90;
});

int main() {
    REG_DISPCNT = VIDEO_MODE(3) | VIDEO_BG2_ENABLE;

    while (true) {

    }
}
