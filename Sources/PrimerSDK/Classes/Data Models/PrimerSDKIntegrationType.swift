//
//  PrimerIntegrationType.swift
//  PrimerSDK
//
//  Created by Evangelos on 19/12/22.
//

#if canImport(UIKit)

import Foundation

internal enum PrimerSDKIntegrationType: String, Codable {
    case dropIn     = "DROP_IN"
    case headless   = "HEADLESS"
}

#endif
