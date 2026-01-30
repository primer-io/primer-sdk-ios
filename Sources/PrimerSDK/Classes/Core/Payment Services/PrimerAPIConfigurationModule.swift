//
//  PrimerAPIConfigurationModule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation

typealias JWTToken = String

protocol PrimerAPIConfigurationModuleProtocol {

    static var apiClient: PrimerAPIClientProtocol? { get set }
    static var clientToken: JWTToken? { get }
    static var decodedJWTToken: DecodedJWTToken? { get }
    static var apiConfiguration: PrimerAPIConfiguration? { get }

    static func resetSession()

    func setupSession(
        forClientToken clientToken: String,
        requestDisplayMetadata: Bool,
        requestClientTokenValidation: Bool,
        requestVaultedPaymentMethods: Bool
    ) async throws
    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) async throws
    func storeRequiredActionClientToken(_ newClientToken: String) async throws
}

// swiftlint:disable file_length
// swiftlint:disable type_body_length
final class PrimerAPIConfigurationModule: PrimerAPIConfigurationModuleProtocol, LogReporter {

    static var apiClient: PrimerAPIClientProtocol?

    private static let queue = DispatchQueue(label: "com.primer.configurationQueue")

    static var clientToken: JWTToken? {
        get {
            if PrimerAPIConfigurationModule.decodedJWTToken == nil {
                AppState.current.clientToken = nil
                return nil
            }

            return AppState.current.clientToken
        }
        set {
            if newValue?.decodedJWTToken != nil {
                AppState.current.clientToken = newValue
            } else {
                PrimerAPIConfigurationModule.resetSession()
            }
        }
    }

    static var apiConfiguration: PrimerAPIConfiguration? {
        get {
            AppState.current.apiConfiguration
        }
        set {
            if PrimerAPIConfigurationModule.clientToken != nil {
                AppState.current.apiConfiguration = newValue
            } else {
                PrimerAPIConfigurationModule.resetSession()
            }
        }
    }

    static var decodedJWTToken: DecodedJWTToken? {
        guard let decodedJWTToken = AppState.current.clientToken?.decodedJWTToken,
              let expDate = decodedJWTToken.expDate,
              expDate > Date() else {
            return nil
        }

        return decodedJWTToken
    }

    static var cacheKey: String? {
        guard let cacheKey = Self.clientToken else {
            return nil
        }
        return cacheKey
    }

    static func resetSession() {
        AppState.current.clientToken = nil
        AppState.current.apiConfiguration = nil
    }

    func setupSession(
        forClientToken clientToken: String,
        requestDisplayMetadata: Bool = true,
        requestClientTokenValidation: Bool = true,
        requestVaultedPaymentMethods: Bool = false
    ) async throws {
        do {
            try await validateClientToken(
                clientToken,
                requestRemoteClientTokenValidation: requestClientTokenValidation
            )
            let apiConfiguration = try await fetchConfigurationAndVaultedPaymentMethodsIfNeeded(
                requestDisplayMetadata: requestDisplayMetadata,
                requestVaultedPaymentMethods: requestVaultedPaymentMethods
            )
            PrimerAPIConfigurationModule.clientToken = clientToken
            PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
            reportAllowedCardNetworks()
        } catch {
            PrimerAPIConfigurationModule.clientToken = nil
            PrimerAPIConfigurationModule.apiConfiguration = nil
            throw error
        }
    }

    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) async throws {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
              let cacheKey = Self.cacheKey
        else {
            throw handled(primerError: .invalidClientToken())
        }

        let apiClient: PrimerAPIClientProtocol = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
        let (configuration, responseHeaders) = try await apiClient.requestPrimerConfigurationWithActions(
            clientToken: decodedJWTToken,
            request: actionsRequest
        )

        try? await ImageFileProcessor().process(configuration: configuration)

        PrimerAPIConfigurationModule.apiConfiguration?.clientSession = configuration.clientSession
        PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules = configuration.checkoutModules
        let cachedData = ConfigurationCachedData(config: configuration, headers: responseHeaders)
        ConfigurationCache.shared.setData(cachedData, forKey: cacheKey)
    }

    func storeRequiredActionClientToken(_ newClientToken: String) async throws {
        do {
            try await validateClientToken(newClientToken, requestRemoteClientTokenValidation: true)
            PrimerAPIConfigurationModule.clientToken = newClientToken
        } catch {
            PrimerAPIConfigurationModule.clientToken = nil
            PrimerAPIConfigurationModule.apiConfiguration = nil
            throw error
        }
    }

    // MARK: - HELPERS

    private func validateClientToken(
        _ clientToken: String,
        requestRemoteClientTokenValidation: Bool
    ) async throws {
        _ = try validateClientTokenInternally(clientToken)

        let isAutoPaymentHandling = PrimerSettings.current.paymentHandling == .auto
        if !requestRemoteClientTokenValidation || isAutoPaymentHandling {
            AppState.current.clientToken = clientToken
        } else {
            try await validateClientTokenRemotely(clientToken)
        }
    }

    private func validateClientTokenInternally(_ tokenToValidate: JWTToken) throws -> JWTToken {
        guard var currentDecodedToken = tokenToValidate.decodedJWTToken,
              let expDate = currentDecodedToken.expDate,
              expDate > Date() else {
            throw handled(primerError: .invalidClientToken())
        }

        let previousDecodedToken = PrimerAPIConfigurationModule.decodedJWTToken

        currentDecodedToken.configurationUrl = currentDecodedToken.configurationUrl?.replacingOccurrences(of: "10.0.2.2:8080",
                                                                                                          with: "localhost:8080")
        currentDecodedToken.coreUrl = currentDecodedToken.coreUrl?.replacingOccurrences(of: "10.0.2.2:8080",
                                                                                        with: "localhost:8080")
        currentDecodedToken.pciUrl = currentDecodedToken.pciUrl?.replacingOccurrences(of: "10.0.2.2:8080",
                                                                                      with: "localhost:8080")

        if currentDecodedToken.env == nil {
            currentDecodedToken.env = previousDecodedToken?.env
        }

        if currentDecodedToken.analyticsUrl == nil {
            currentDecodedToken.analyticsUrl = previousDecodedToken?.analyticsUrl
        }

        if currentDecodedToken.configurationUrl == nil {
            currentDecodedToken.configurationUrl = previousDecodedToken?.configurationUrl
        }

        if currentDecodedToken.coreUrl == nil {
            currentDecodedToken.coreUrl = previousDecodedToken?.coreUrl
        }

        if currentDecodedToken.pciUrl == nil {
            currentDecodedToken.pciUrl = previousDecodedToken?.pciUrl
        }

        var segments: [String] = tokenToValidate.split(separator: ".").compactMap({ String($0) })

        var tmpSecondSegment: String?
        if let data = try? JSONEncoder().encode(currentDecodedToken),
           let dataStr = String(data: data.base64EncodedData(), encoding: .utf8) {
            tmpSecondSegment = dataStr
        }

        if segments.count > 1, let tmpSecondSegment = tmpSecondSegment {
            segments[1] = tmpSecondSegment
        } else if segments.count == 1, let tmpSecondSegment = tmpSecondSegment {
            segments.append(tmpSecondSegment)
        }

        return segments.joined(separator: ".").base64RFC4648Format
    }

    private func validateClientTokenRemotely(_ clientToken: JWTToken) async throws {
        let clientTokenRequest = Request.Body.ClientTokenValidation(clientToken: clientToken)

        let apiClient: PrimerAPIClientProtocol = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
        _ = try await apiClient.validateClientToken(request: clientTokenRequest)
    }

    // swiftlint:disable:next function_body_length
    private func fetchConfiguration(requestDisplayMetadata: Bool) async throws -> PrimerAPIConfiguration {
        let start = Date().millisecondsSince1970

        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken,
              let cacheKey = Self.cacheKey
        else {
            throw handled(primerError: .invalidClientToken())
        }

        return try await withCheckedThrowingContinuation { continuation in
            PrimerAPIConfigurationModule.queue.sync {
                if cachingEnabled, let cachedConfig = ConfigurationCache.shared.data(forKey: cacheKey) {
                    let event = Analytics.Event.message(
                        message: "Configuration cache hit with key: \(cacheKey)",
                        messageType: .info,
                        severity: .info
                    )
                    Analytics.Service.fire(event: event)
                    logger.debug(message: "Cached config used")
                    self.recordLoadedEvent(start, source: .cache)
                    return continuation.resume(returning: cachedConfig.config)

                }

                let task = CancellableTask<PrimerAPIConfiguration> {
                    let requestParameters = Request.URLParameters.Configuration(
                        skipPaymentMethodTypes: [],
                        requestDisplayMetadata: requestDisplayMetadata
                    )

                    let apiClient: PrimerAPIClientProtocol = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
                    let (configuration, responseHeaders) = try await apiClient.fetchConfiguration(
                        clientToken: clientToken,
                        requestParameters: requestParameters
                    )

                    try? await ImageFileProcessor().process(configuration: configuration)

                    // Cache the result
                    if self.cachingEnabled {
                        let cachedData = ConfigurationCachedData(config: configuration, headers: responseHeaders)
                        ConfigurationCache.shared.setData(cachedData, forKey: cacheKey)
                    }

                    self.recordLoadedEvent(start, source: .network)
                    return configuration
                }

                Task {
                    do {
                        let config = try await task.wait()
                        continuation.resume(returning: config)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    private func recordLoadedEvent(_ start: Int, source: Analytics.Event.ConfigurationLoadingSource) {
        let end = Date().millisecondsSince1970
        let interval = end - start
        let showEvent = Analytics.Event.configurationLoading(duration: interval, source: source)
        Analytics.Service.fire(events: [showEvent])
    }

    private func fetchConfigurationAndVaultedPaymentMethodsIfNeeded(
        requestDisplayMetadata: Bool,
        requestVaultedPaymentMethods: Bool
    ) async throws -> PrimerAPIConfiguration {
        if requestVaultedPaymentMethods {
            let vaultService: VaultServiceProtocol = VaultService(apiClient: PrimerAPIClient())
            try await vaultService.fetchVaultedPaymentMethods()
            return try await fetchConfiguration(requestDisplayMetadata: true)
        } else {
            return try await fetchConfiguration(requestDisplayMetadata: requestDisplayMetadata)
        }
    }

    private func reportAllowedCardNetworks() {
        let networksDescription = [CardNetwork].allowedCardNetworks.map(\.rawValue).joined(separator: ", ")
        let event = Analytics.Event.message(
            message: "Merchant supported networks: \(networksDescription)",
            messageType: .other,
            severity: .info
        )
        Analytics.Service.fire(event: event)
    }

    private var cachingEnabled: Bool {
        PrimerSettings.current.clientSessionCachingEnabled
    }
}
// swiftlint:enable type_body_length
// swiftlint:enable file_length
