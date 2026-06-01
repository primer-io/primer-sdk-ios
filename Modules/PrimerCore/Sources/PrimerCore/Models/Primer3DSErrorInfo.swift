//
//  Primer3DSErrorInfo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

public struct Primer3DSErrorInfo {
    @_spi(PrimerInternal) public let errorId: String
    @_spi(PrimerInternal) public let errorDescription: String
    @_spi(PrimerInternal) public let recoverySuggestion: String?
    @_spi(PrimerInternal) public let threeDsErrorCode: Int?
    @_spi(PrimerInternal) public let threeDsErrorType: String?
    @_spi(PrimerInternal) public let threeDsErrorComponent: String?
    @_spi(PrimerInternal) public let threeDsSdkTranscationId: String?
    @_spi(PrimerInternal) public let threeDsSErrorVersion: String?
    @_spi(PrimerInternal) public let threeDsErrorDetail: String?
    
    @_spi(PrimerInternal) public init(
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
