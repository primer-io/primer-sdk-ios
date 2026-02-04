//
//  3DS.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation
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
    
    struct BeginAuthResponse: Decodable {

        let authentication: ThreeDSAuthenticationProtocol
        let token: PrimerPaymentMethodTokenData
        let resumeToken: String
        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case authentication
            case token
            case resumeToken
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let declinedResponse = try? container.decode(ThreeDS.DeclinedAPIResponse.self,
                                                            forKey: .authentication) {
                authentication = declinedResponse
            } else if let skippedResponse = try? container.decode(ThreeDS.SkippedAPIResponse.self,
                                                                  forKey: .authentication) {
                authentication = skippedResponse
            } else if let appV2ChallengeResponse = try? container.decode(ThreeDS.AppV2ChallengeAPIResponse.self,
                                                                         forKey: .authentication) {
                authentication = appV2ChallengeResponse
            } else if let browserV2ChallengeResponse = try? container.decode(ThreeDS.BrowserV2ChallengeAPIResponse.self,
                                                                             forKey: .authentication) {
                authentication = browserV2ChallengeResponse
            } else if let browserV1ChallengeResponse = try? container.decode(ThreeDS.BrowserV1ChallengeAPIResponse.self,
                                                                             forKey: .authentication) {
                authentication = browserV1ChallengeResponse
            } else if let successResponse = try? container.decode(Authentication.self,
                                                                  forKey: .authentication) {
                authentication = successResponse
            } else if let methodResponse = try? container.decode(ThreeDS.MethodAPIResponse.self,
                                                                 forKey: .authentication) {
                authentication = methodResponse
            } else {
                throw handled(error: InternalError.failedToDecode(message: "ThreeDS.BeginAuthResponse"))
            }

            resumeToken = try container.decode(String.self, forKey: .resumeToken)
            token = try container.decode(PrimerPaymentMethodTokenData.self, forKey: .token)
        }

        init(
            authentication: ThreeDSAuthenticationProtocol,
            token: PrimerPaymentMethodTokenData,
            resumeToken: String
        ) {
            self.authentication = authentication
            self.token = token
            self.resumeToken = resumeToken
        }
    }

    struct PostAuthResponse: Codable {

        let token: PrimerPaymentMethodTokenData
        let resumeToken: String
        let authentication: Authentication?
    }
}
