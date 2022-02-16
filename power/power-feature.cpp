/*
 * Copyright (C) 2023 Paranoid Android
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <aidl/vendor/aospa/power/BnPowerFeature.h>
#include <android-base/file.h>
#include <android-base/strings.h>

using ::android::base::WriteStringToFile;
using ::aidl::vendor::aospa::power::Feature;

namespace aidl {
namespace vendor {
namespace aospa {
namespace power {

bool isDeviceSpecificModeSupported(Feature feature, bool* _aidl_return) {
    switch (feature) {
        case Feature::DOUBLE_TAP:
            *_aidl_return = true;
            return true;
        default:
            return false;
    }
}

bool setDeviceSpecificFeature(Feature feature, bool enabled) {
    switch (feature) {
        case Feature::DOUBLE_TAP:
            ::android::base::WriteStringToFile(enabled ? "sod_enable,1" : "sod_enable,0",
                                               "/sys/devices/virtual/sec/tsp/cmd");
            ::android::base::WriteStringToFile(enabled ? "1" : "0",
                                               "/sys/devices/dsi_panel_driver/pre_sod_mode");
            return true;
        default:
            return false;
    }
}

}  // namespace power
}  // namespace aospa
}  // namespace vendor
}  // namespace aidl