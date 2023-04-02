#include <cmath>
#include <numbers>

#include <agbabi.h>
#include <gcem.hpp>
#include <seven/hw/video.h>
#include <seven/hw/video/bg_bitmap.h>

#include "angle_lut.hpp"
#include "fixed.hpp"
#include "lut_generator.hpp"

static constexpr auto fine_angles = 8192;
static constexpr auto fine_angles_2 = fine_angles / 2;
static constexpr auto fine_angles_4 = fine_angles / 4;
static constexpr auto fine_angles_8 = fine_angles / 8;

static constexpr auto fine_angle_tangent = lut::make<fine_angles_2>([](std::size_t i) {
    return gcem::tan((i - (fine_angles / 4.0) + 0.5) * std::numbers::pi_v<double> * 2.0 / fine_angles);
});

static constexpr auto screen_width = MODE3_WIDTH;

static constexpr auto focal_length = (screen_width / 2.0f) / fine_angle_tangent[fine_angles_4 + fine_angles_8];

static constexpr auto view_angle_to_x = angle_lut::make<fine_angles_2>([](std::size_t i) {
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
static constexpr auto angle_one_degree = angle(1.0 / (2.0 * std::numbers::pi_v<double>));

static constexpr auto x_to_view_angle = lut::make<screen_width>([](std::size_t i) {
    auto x = std::size_t{};
    while (int(view_angle_to_x.at(x)) > int(i)) {
        ++x;
    }
    return angle::from_int<13>(x) - angle_90;
});

int main() {
    REG_DISPCNT = VIDEO_MODE(3) | VIDEO_BG2_ENABLE;

    auto a = angle{};
    auto va = int{};

    while (true) {
        for (int i = 0; i < 240; ++i) {
            va = x_to_view_angle[i].to_int<16>();
            if (va == -1) {
                int fifty = 50;
            }
        }

        auto x = int(view_angle_to_x[a]);
        if (x != 0 && x != 240) {
            int fifty = 50;
        }
        a += angle_one_degree;
    }
}
