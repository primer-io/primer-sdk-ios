//
//  AnalyticsContextKeys.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal) public extension AnalyticsContextKeys {
    static let initProtocolVersion = "initProtocolVersion"
    static let threeDsSdkVersion = "threeDsSdkVersion"
    static let threeDsSdkProvider = "threeDsSdkProvider"
    static let threeDsWrapperSdkVersion = "threeDsWrapperSdkVersion"
    static let threeDsErrorCode = "threeDsErrorCode"
    static let threeDsErrorComponent = "threeDsErrorComponent"
    static let threeDsErrorDescription = "threeDsErrorDescription"
    static let threeDsErrorDetail = "threeDsErrorDetail"
    static let threeDsSdkTranscationId = "threeDsSdkTranscationId"
    static let protocolVersion = "protocolVersion"
}
