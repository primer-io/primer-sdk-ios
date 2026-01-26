//
//  Primer3DSErrorInfo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  Primer3DSErrorContainer.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public struct Primer3DSErrorInfo {
    let errorId: String
    let errorDescription: String
    let recoverySuggestion: String?
    let threeDsErrorCode: Int?
    let threeDsErrorType: String?
    let threeDsErrorComponent: String?
    let threeDsSdkTranscationId: String?
    let threeDsSErrorVersion: String?
    let threeDsErrorDetail: String?
}

extension AnalyticsContextKeys {
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
