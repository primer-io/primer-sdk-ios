//
//  3DSService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
// swiftlint:disable large_tuple

import Foundation
import UIKit

#if canImport(Primer3DS)
import Primer3DS
#endif

protocol ThreeDSServiceProtocol {

    static var apiClient: PrimerAPIClientProtocol? { get set }

    func perform3DS(
        paymentMethodTokenData: PrimerPaymentMethodTokenData,
        sdkDismissed: (() -> Void)?
    ) async throws -> String
}

// MARK: MISSING_TESTS
final class ThreeDSService: ThreeDSServiceProtocol, LogReporter {

    static var apiClient: PrimerAPIClientProtocol?

    private var threeDSSDKWindow: UIWindow?
    private var initProtocolVersion: ThreeDS.ProtocolVersion?
    private var resumePaymentToken: String?

    #if canImport(Primer3DS)
    private var primer3DS: Primer3DS!
    #endif

    private var paymentMethodType: String?

    func perform3DS(
        paymentMethodTokenData: PrimerPaymentMethodTokenData,
        sdkDismissed: (() -> Void)?
    ) async throws -> String {
        #if canImport(Primer3DS)

        defer {
            Task { await cleanup() }
        }

        do {
            return try await executeAuthentication(paymentMethodTokenData: paymentMethodTokenData, sdkDismissed: sdkDismissed)
        } catch {
            return try await handleAuthenticationError(paymentMethodTokenData: paymentMethodTokenData, error: error)
        }
        #else
        try await handleMissingSDK(paymentMethodTokenData: paymentMethodTokenData)
        #endif
    }

    private func validate() async throws {
        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else {
            throw InternalError.failedToPerform3dsAndShouldBreak(error: PrimerError.invalidClientToken())
        }

        guard AppState.current.apiConfiguration != nil else {
            throw InternalError.failedToPerform3dsAndShouldBreak(error: PrimerError.missingPrimerConfiguration())
        }
    }

    #if canImport(Primer3DS)
    @MainActor
    private func cleanup() {
        let dismiss3DSUIEvent = Analytics.Event.ui(
            action: .dismiss,
            context: nil,
            extra: nil,
            objectType: .thirdPartyView,
            objectId: nil,
            objectClass: nil,
            place: .threeDSScreen
        )
        Analytics.Service.fire(events: [dismiss3DSUIEvent])

        threeDSSDKWindow?.isHidden = true
        threeDSSDKWindow = nil
        primer3DS?.cleanup()
    }

    private func executeAuthentication(paymentMethodTokenData: PrimerPaymentMethodTokenData, sdkDismissed: (() -> Void)?) async throws -> String {
        paymentMethodType = paymentMethodTokenData.paymentMethodType

        try await validate()
        try await initializePrimer3DSSdk()
        let sdkAuthResult = try await create3DsAuthData(paymentMethodTokenData: paymentMethodTokenData)
        initProtocolVersion = ThreeDS.ProtocolVersion(rawValue: sdkAuthResult.maxSupportedThreeDsProtocolVersion)
        let authorizationResult = try await initialize3DSAuthorization(
            sdkAuthResult: sdkAuthResult,
            paymentMethodTokenData: paymentMethodTokenData
        )
        resumePaymentToken = authorizationResult.resumeToken
        _ = try await perform3DSChallenge(
            threeDSAuthData: authorizationResult.serverAuthData,
            threeDsAppRequestorUrl: authorizationResult.threeDsAppRequestorUrl
        )
        sdkDismissed?()

        guard let token = paymentMethodTokenData.token else {
            throw handled(primerError: .invalidClientToken())
        }

        let result = try await finalize3DSAuthorization(paymentMethodToken: token, continueInfo: nil)
        resumePaymentToken = result.resumeToken
        return result.resumeToken
    }

    private func handleAuthenticationError(paymentMethodTokenData: PrimerPaymentMethodTokenData, error: Error) async throws -> String {
        var continueInfo: ThreeDS.ContinueInfo?
        if case InternalError.noNeedToPerform3ds = error {
            guard let resumePaymentToken else { throw handled(primerError: .invalidValue(key: "resumeToken")) }
            return resumePaymentToken
        } else if case InternalError.failedToPerform3dsAndShouldBreak(let primerErr) = error {
            ErrorHandler.handle(error: primerErr)
            throw primerErr
        } else if case InternalError.failedToPerform3dsButShouldContinue(let primer3DSErrorContainer) = error {
            ErrorHandler.handle(error: primer3DSErrorContainer)
            continueInfo = primer3DSErrorContainer.continueInfo
        } else {
            let errContainer = Primer3DSErrorContainer.underlyingError(error: error)
            continueInfo = ThreeDS.ContinueInfo(
                initProtocolVersion: initProtocolVersion?.rawValue,
                error: errContainer
            )
            ErrorHandler.handle(error: error)
        }

        guard let token = paymentMethodTokenData.token else {
            throw handled(primerError: .invalidClientToken())
        }

        do {
            let result = try await finalize3DSAuthorization(paymentMethodToken: token, continueInfo: continueInfo)
            resumePaymentToken = result.resumeToken
            return result.resumeToken
        } catch {
            throw error.primerError
        }
    }

    private func initializePrimer3DSSdk() async throws {
        let token = try fetchToken()
        let config = try fetchConfiguration()
        let apiKey = try fetchAPIKey(from: config)
        let certs = buildCertificates(from: config)
        let env = Environment(rawValue: token.env ?? "") ?? .sandbox
        primer3DS = Primer3DS(environment: env)
        try checkVersionAndInit(apiKey: apiKey, certs: certs)
    }

    private func create3DsAuthData(
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> SDKAuthResult {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw InternalError.failedToPerform3dsAndShouldBreak(error: PrimerError.invalidClientToken())
        }

        let network = paymentMethodTokenData.paymentInstrumentData?.binData?.network
        let cardNetwork = CardNetwork(cardNetworkStr: network ?? "")
        let directoryServerNetwork = DirectoryServerNetwork.from(cardNetworkIdentifier: cardNetwork.rawValue)
        let supportedThreeDsProtocolVersions = decodedJWTToken.supportedThreeDsProtocolVersions ?? []

        do {
            let result = try primer3DS.createTransaction(
                directoryServerNetwork: directoryServerNetwork,
                supportedThreeDsProtocolVersions: supportedThreeDsProtocolVersions
            )
            return result
        } catch {
            guard let primer3DSError = error as? Primer3DSError else {
                throw InternalError.failedToPerform3dsAndShouldBreak(error: error)
            }
            throw InternalError.failedToPerform3dsButShouldContinue(error: createPrimer3DSError(from: primer3DSError))
        }
    }

    private func initialize3DSAuthorization(
        sdkAuthResult: SDKAuthResult,
        paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> (
        serverAuthData: ThreeDS.ServerAuthData,
        resumeToken: String,
        threeDsAppRequestorUrl: URL?
    ) {
        var threeDsAppRequestorUrl: URL?
        if sdkAuthResult.maxSupportedThreeDsProtocolVersion.compareWithVersion("2.1") == .orderedDescending {
            if let urlStr = PrimerSettings.current.paymentMethodOptions.threeDsOptions?.threeDsAppRequestorUrl,
               urlStr.hasPrefix("https"),
               let url = URL(string: urlStr) {
                threeDsAppRequestorUrl = url
            } else {
                let message =
                    """
                    threeDsAppRequestorUrl is not in a valid format (\"https://applink\"). \
                    In case you want to support redirecting back during the OOB flows, \
                    please set correct threeDsAppRequestorUrl in PrimerThreeDsOptions during SDK initialization.
                    """
                logger.warn(message: message)
            }
        }

        let threeDSecureBeginAuthRequest = ThreeDS.BeginAuthRequest(
            maxProtocolVersion: sdkAuthResult.maxSupportedThreeDsProtocolVersion,
            device: ThreeDS.SDKAuthData(
                sdkAppId: sdkAuthResult.authData.sdkAppId,
                sdkTransactionId: sdkAuthResult.authData.sdkTransactionId,
                sdkTimeout: sdkAuthResult.authData.sdkTimeout,
                sdkEncData: sdkAuthResult.authData.sdkEncData,
                sdkEphemPubKey: sdkAuthResult.authData.sdkEphemPubKey,
                sdkReferenceNumber: sdkAuthResult.authData.sdkReferenceNumber
            )
        )

        return try await withCheckedThrowingContinuation { continuation in
            requestInitialize3DSAuthorization(
                paymentMethodTokenData: paymentMethodTokenData,
                threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest
            ) { result in
                switch result {
                case .success(let beginAuthResponse):
                    switch beginAuthResponse.authentication.responseCode {
                    case .authSuccess,
                         .authFailed,
                         .METHOD,
                         .notPerformed,
                         .skipped:
                        self.resumePaymentToken = beginAuthResponse.resumeToken

                        let internalErr = InternalError.noNeedToPerform3ds(
                            status: beginAuthResponse.authentication.responseCode.rawValue
                        )
                        continuation.resume(throwing: internalErr)
                    case .challenge:
                        let authentication = beginAuthResponse.authentication
                        let serverAuthData = ThreeDS.ServerAuthData(acsReferenceNumber: authentication.acsReferenceNumber,
                                                                    acsSignedContent: authentication.acsSignedContent,
                                                                    acsTransactionId: authentication.acsTransactionId,
                                                                    responseCode: authentication.responseCode.rawValue,
                                                                    transactionId: authentication.transactionId)

                        continuation.resume(returning: (serverAuthData, beginAuthResponse.resumeToken, threeDsAppRequestorUrl))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    @MainActor
    private func perform3DSChallenge(
        threeDSAuthData: Primer3DSServerAuthData,
        threeDsAppRequestorUrl: URL?
    ) async throws -> Primer3DSCompletion {
        guard let primer3DS else {
            throw InternalError.failedToPerform3dsButShouldContinue(error: createPrimer3DSError(
                from: Primer3DSError.initializationError(error: nil, warnings: "Uninitialized SDK")
            ))
        }

        let rootViewController = ClearViewController()
        let window: UIWindow
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        window.rootViewController = rootViewController
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindow.Level.normal
        window.makeKeyAndVisible()

        threeDSSDKWindow = window

        let present3DSUIEvent = Analytics.Event.ui(
            action: Analytics.Event.Property.Action.present,
            context: nil,
            extra: nil,
            objectType: .thirdPartyView,
            objectId: nil,
            objectClass: nil,
            place: .threeDSScreen
        )

        Analytics.Service.fire(events: [present3DSUIEvent])

        return try await withCheckedThrowingContinuation { continuation in
            primer3DS.performChallenge(
                threeDSAuthData: threeDSAuthData,
                threeDsAppRequestorUrl: threeDsAppRequestorUrl,
                presentOn: rootViewController
            ) { [weak self] primer3DSCompletion, err in
                guard let self else { return }
                if let primer3DSError = err as? Primer3DSError {
                    continuation.resume(
                        throwing: InternalError.failedToPerform3dsButShouldContinue(error: createPrimer3DSError(from: primer3DSError))
                    )
                } else if let primer3DSCompletion {
                    continuation.resume(returning: primer3DSCompletion)
                } else {
                    let err = PrimerError.invalidValue(key: "performChallenge.result")
                    continuation.resume(throwing: InternalError.failedToPerform3dsAndShouldBreak(error: err))
                }
            }
        }
    }

    private func requestInitialize3DSAuthorization(
        paymentMethodTokenData: PrimerPaymentMethodTokenData,
        threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
        completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void
    ) {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            return completion(.failure(InternalError.failedToPerform3dsAndShouldBreak(error: PrimerError.invalidClientToken())))
        }

        let apiClient: PrimerAPIClientProtocol = ThreeDSService.apiClient ?? PrimerAPIClient()
        apiClient.begin3DSAuth(clientToken: decodedJWTToken,
                               paymentMethodTokenData: paymentMethodTokenData,
                               threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest) { result in
            switch result {
            case .failure(let underlyingErr):
                let primerErr = underlyingErr.primerError
                completion(.failure(InternalError.failedToPerform3dsAndShouldBreak(error: primerErr)))

            case .success(let res):
                completion(.success(res))
            }
        }
    }
    #else
    private func handleMissingSDK(paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String {
        let missingSdkErr = handled(error: Primer3DSErrorContainer.missingSdkDependency())
        let continueErrorInfo = missingSdkErr.continueInfo

        do {
            try await validate()

            guard let token = paymentMethodTokenData.token else {
                throw handled(primerError: .invalidClientToken())
            }

            let threeDsAuth = try await finalize3DSAuthorization(paymentMethodToken: token, continueInfo: continueErrorInfo)
            resumePaymentToken = threeDsAuth.resumeToken
            return threeDsAuth.resumeToken
        } catch {
            throw error.primerError
        }
    }
    #endif

    private func finalize3DSAuthorization(
        paymentMethodToken: String,
        continueInfo: ThreeDS.ContinueInfo?
    ) async throws -> ThreeDS.PostAuthResponse {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw InternalError.failedToPerform3dsAndShouldBreak(error: PrimerError.invalidClientToken())
        }

        let continueInfo = continueInfo ?? ThreeDS.ContinueInfo(
            initProtocolVersion: initProtocolVersion?.rawValue,
            error: nil
        )
        let apiClient: PrimerAPIClientProtocol = ThreeDSService.apiClient ?? PrimerAPIClient()

        do {
            let response = try await apiClient.continue3DSAuth(
                clientToken: decodedJWTToken,
                threeDSTokenId: paymentMethodToken,
                continueInfo: continueInfo
            )
            return response
        } catch {
            throw InternalError.failedToPerform3dsAndShouldBreak(error: error.primerError)
        }
    }
}

#if canImport(Primer3DS)
private extension ThreeDSService {
    func fetchToken() throws -> DecodedJWTToken {
        guard let token = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw InternalError.failedToPerform3dsAndShouldBreak(error: PrimerError.invalidClientToken())
        }
        return token
    }

    func fetchConfiguration() throws -> PrimerAPIConfiguration {
        guard let configuration = AppState.current.apiConfiguration else {
            throw handled(primerError: .missingPrimerConfiguration())
        }
        return configuration
    }

    func fetchAPIKey(from config: PrimerAPIConfiguration) throws -> String {
        guard let key = config.keys?.netceteraApiKey else {
            throw InternalError.failedToPerform3dsButShouldContinue(
                error: Primer3DSErrorContainer.missing3DSConfiguration(
                    missingKey: "netceteraApiKey"
                )
            )
        }
        return key
    }

    func buildCertificates(from config: PrimerAPIConfiguration) -> [Primer3DSCertificate] {
        // Once `threeDSecureIoCertificates` is removed from the response in the future we can remove the check
        let ioCerts = config.keys?.threeDSecureIoCertificates ?? []
        let providerCerts = config.keys?.threeDsProviderCertificates ?? []
        return (ioCerts + providerCerts).map { certificate in
            ThreeDS.Cer(
                cardScheme: certificate.cardNetwork,
                rootCertificate: certificate.rootCertificate,
                encryptionKey: certificate.encryptionKey
            )
        }
    }

    func checkVersionAndInit(apiKey: String, certs: [Primer3DSCertificate]) throws {
        // ⚠️  Property version doesn't exist on version before 1.1.0, so PrimerSDK won't build
        //     if Primer3DS is not equal or above 1.1.0
        if Primer3DS.version.compareWithVersion("1.1.1") == .orderedDescending ||
            Primer3DS.version.compareWithVersion("1.1.1") == .orderedSame {
            do {
                primer3DS.is3DSSanityCheckEnabled = PrimerSettings.current.debugOptions.is3DSSanityCheckEnabled
                try primer3DS.initializeSDK(apiKey: apiKey, certificates: certs)

            } catch {
                if let primer3DSError = error as? Primer3DSError {
                    throw (InternalError.failedToPerform3dsButShouldContinue(error: createPrimer3DSError(from: primer3DSError)))
                } else {
                    throw(InternalError.failedToPerform3dsAndShouldBreak(error: error))
                }
            }

        } else {
            throw(
                InternalError.failedToPerform3dsButShouldContinue(
                    error: Primer3DSErrorContainer.invalid3DSSdkVersion(
                        invalidVersion: Primer3DS.version,
                        validVersion: "1.1.0"
                    )
                )
            )
        }
    }

    private func createPrimer3DSError(from primer3DSError: Primer3DSError) -> Primer3DSErrorContainer {
        return Primer3DSErrorContainer.primer3DSSdkError(
            paymentMethodType: self.paymentMethodType,
            initProtocolVersion: self.initProtocolVersion?.rawValue,
            errorInfo: Primer3DSErrorInfo(primer3DSError)
        )
    }
}

private extension Primer3DSErrorInfo {
    init(_ primer3DSError: Primer3DSError) {
        errorId = primer3DSError.errorId
        errorDescription = primer3DSError.errorDescription
        recoverySuggestion = primer3DSError.recoverySuggestion
        threeDsErrorCode = primer3DSError.threeDsErrorCode
        threeDsErrorType = primer3DSError.threeDsErrorType
        threeDsErrorComponent = primer3DSError.threeDsErrorComponent
        threeDsSdkTranscationId = primer3DSError.threeDsSdkTranscationId
        threeDsSErrorVersion = primer3DSError.threeDsSErrorVersion
        threeDsErrorDetail = primer3DSError.threeDsErrorDetail
    }
}
#endif
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable large_tuple
// swiftlint:enable file_length
