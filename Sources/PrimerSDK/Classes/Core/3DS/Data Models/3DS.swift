//
//  3DS.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation
import PrimerNetworking
#if canImport(Primer3DS)
import Primer3DS
#endif

extension ThreeDS {
    final class ContinueInfo: Encodable {

        var platform: String
        var threeDsWrapperSdkVersion: String?
        var threeDsSdkProvider: String?
        var threeDsSdkVersion: String?
        var initProtocolVersion: String?
        var status: ThreeDS.Status
        var error: ThreeDS.ContinueInfo.Error?

        init(
            initProtocolVersion: String?,
            error: Primer3DSErrorContainer?
        ) {
            self.platform = Primer.shared.integrationOptions?.reactNativeVersion == nil ? "IOS_NATIVE" : "RN_IOS"
            self.initProtocolVersion = initProtocolVersion

            #if canImport(Primer3DS)
            self.threeDsWrapperSdkVersion = Primer3DS.version
            self.threeDsSdkProvider = Primer3DS.threeDsSdkProvider
            self.threeDsSdkVersion = Primer3DS.threeDsSdkVersion
            #endif

            if let primer3DSErr = error {
                self.status = .failure
                self.error = ThreeDS.ContinueInfo.Error(error: primer3DSErr)
            } else {
                self.status = .success
            }
        }

        // swiftlint:disable:next nesting
        final class Error: Encodable {

            var reasonCode: String
            var reasonText: String
            var recoverySuggestion: String?
            var threeDsErrorDescription: String?
            var threeDsErrorCode: Int?
            var threeDsErrorComponent: String?
            var threeDsErrorDetail: String?
            var threeDsSdkTranscationId: String?
            var protocolVersion: String?

            init(error: Primer3DSErrorContainer) {
                self.reasonCode = error.errorId.uppercased().replacingOccurrences(of: "-", with: "_")
                self.reasonText = error.plainDescription
                self.recoverySuggestion = error.recoverySuggestion
                self.threeDsErrorDescription = error.threeDsErrorDescription
                self.threeDsErrorCode = error.threeDsErrorCode
                self.threeDsErrorComponent = error.threeDsErrorComponent
                self.threeDsErrorDetail = error.threeDsErrorDetail
                self.threeDsSdkTranscationId = error.threeDsSdkTranscationId
                self.protocolVersion = error.initProtocolVersion
            }
        }
    }
    
}
