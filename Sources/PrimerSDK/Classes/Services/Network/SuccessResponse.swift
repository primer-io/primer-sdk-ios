//
//  SuccessResponse.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/1/22.
//

#if canImport(UIKit)

import Foundation

typealias DummySuccess = SuccessResponse

internal struct SuccessResponse: Codable {
    let success: Bool
}

#endif
