//
//  VersionUtils.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct VersionUtils {

    /**
     Returns the version string in the format `"major.minor.patch"`

     If `PrimerIntegrationOptions.reactNativeVersion` is set, it will be returned.
     If not, the version specified as `PrimerSDKVersion` in the file `"sources/version.swift"` will be returned.
     */
    static var releaseVersionNumber: String? {
        if let reactNativeVersion = Primer.shared.integrationOptions?.reactNativeVersion {
            return reactNativeVersion
        }

        return PrimerSDKVersion
    }
}
