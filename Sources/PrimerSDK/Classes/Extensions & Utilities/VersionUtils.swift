//
//  VersionUtils.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 26/09/23.
//

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
