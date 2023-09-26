//
//  VersionUtils.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 26/09/23.
//

import Foundation

struct VersionUtils {
    static var releaseVersionNumber: String? {
        if let reactNativeVersion = Primer.shared.integrationOptions?.reactNativeVersion {
            return reactNativeVersion
        }
    
        return PrimerSDKVersion
    }
}
