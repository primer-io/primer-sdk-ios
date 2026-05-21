//
//  Primer3DSErrorInfo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

public struct Primer3DSErrorInfo {
    public let errorId: String
    public let errorDescription: String
    public let recoverySuggestion: String?
    public let threeDsErrorCode: Int?
    public let threeDsErrorType: String?
    public let threeDsErrorComponent: String?
    public let threeDsSdkTranscationId: String?
    public let threeDsSErrorVersion: String?
    public let threeDsErrorDetail: String?
    
    public init(
        errorId: String,
        errorDescription: String,
        recoverySuggestion: String?,
        threeDsErrorCode: Int?,
        threeDsErrorType: String?,
        threeDsErrorComponent: String?,
        threeDsSdkTranscationId: String?,
        threeDsSErrorVersion: String?,
        threeDsErrorDetail: String?
    ) {
        self.errorId = errorId
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion
        self.threeDsErrorCode = threeDsErrorCode
        self.threeDsErrorType = threeDsErrorType
        self.threeDsErrorComponent = threeDsErrorComponent
        self.threeDsSdkTranscationId = threeDsSdkTranscationId
        self.threeDsSErrorVersion = threeDsSErrorVersion
        self.threeDsErrorDetail = threeDsErrorDetail
    }
}

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
