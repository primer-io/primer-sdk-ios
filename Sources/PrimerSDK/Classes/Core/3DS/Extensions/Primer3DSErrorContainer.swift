//
//  Primer3DSErrorContainer.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

extension Primer3DSErrorContainer: @retroactive PrimerErrorProtocol {
    public var exposedError: Error {
        self
    }
    
    public var analyticsContext: [String: Any] {
        var context: [String: Any] = [:]

        context[K.initProtocolVersion] = continueInfo.initProtocolVersion
        context[K.threeDsSdkVersion] = continueInfo.threeDsSdkVersion
        context[K.threeDsSdkProvider] = continueInfo.threeDsSdkProvider
        context[K.threeDsWrapperSdkVersion] = continueInfo.threeDsWrapperSdkVersion

        switch self {
        case let .primer3DSSdkError(paymentMethodType, _, _, errorInfo):
            context[K.reasonCode] = errorInfo.errorId
            context[K.reasonText] = errorInfo.errorDescription
            context[K.threeDsErrorCode] = errorInfo.threeDsErrorCode
            context[K.threeDsErrorComponent] = errorInfo.threeDsErrorComponent
            context[K.threeDsErrorDescription] = errorInfo.errorDescription
            context[K.threeDsErrorDetail] = errorInfo.threeDsErrorDetail
            context[K.threeDsSdkTranscationId] = errorInfo.threeDsSdkTranscationId
            context[K.protocolVersion] = errorInfo.threeDsSErrorVersion
            context[K.errorId] = errorInfo.errorId
            if let paymentMethodType = paymentMethodType {
                context[K.paymentMethodType] = paymentMethodType
            }
        default:
            break
        }

        return context
    }
    
    var continueInfo: ThreeDS.ContinueInfo {
        ThreeDS.ContinueInfo(initProtocolVersion: initProtocolVersion, error: self)
    }
}
