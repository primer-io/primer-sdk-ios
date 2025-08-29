//
//  PrimerAPIConfigurationModule.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

internal typealias JWTToken = String

internal protocol PrimerAPIConfigurationModuleProtocol {

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
    ) -> Promise<Void>
    func setupSession(
        forClientToken clientToken: String,
        requestDisplayMetadata: Bool,
        requestClientTokenValidation: Bool,
        requestVaultedPaymentMethods: Bool

    ) async throws

    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) -> Promise<Void>
    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) async throws

    func storeRequiredActionClientToken(_ newClientToken: String) -> Promise<Void>
    func storeRequiredActionClientToken(_ newClientToken: String) async throws
}

// swiftlint:disable file_length
// swiftlint:disable type_body_length
final class PrimerAPIConfigurationModule: PrimerAPIConfigurationModuleProtocol, LogReporter {

    static var apiClient: PrimerAPIClientProtocol?

    private static let queue = DispatchQueue(label: "com.primer.configurationQueue")
    private static var pendingPromises: [String: Promise<PrimerAPIConfiguration>] = [:]
    private static var pendingTasks: [String: CancellableTask<PrimerAPIConfiguration>] = [:]

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
            return AppState.current.apiConfiguration
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
    ) -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.validateClientToken(clientToken, requestRemoteClientTokenValidation: requestClientTokenValidation)
            }
            .then { () -> Promise<PrimerAPIConfiguration> in
                return self.fetchConfigurationAndVaultedPaymentMethodsIfNeeded(
                    requestDisplayMetadata: requestDisplayMetadata,
                    requestVaultedPaymentMethods: requestVaultedPaymentMethods)
            }
            .done { apiConfiguration in
                PrimerAPIConfigurationModule.clientToken = clientToken
                PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
                self.reportAllowedCardNetworks()
                seal.fulfill()
            }
            .catch { err in
                PrimerAPIConfigurationModule.clientToken = nil
                PrimerAPIConfigurationModule.apiConfiguration = nil
                seal.reject(err)
            }
        }
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

    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) -> Promise<Void> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
                  let cacheKey = Self.cacheKey else {
                return seal.reject(handled(primerError: .invalidClientToken()))
            }

            let apiClient: PrimerAPIClientProtocol = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
            apiClient.requestPrimerConfigurationWithActions(clientToken: decodedJWTToken,
                                                            request: actionsRequest) { result, responseHeaders in
                switch result {
                case .success(let configuration):
                    _ = ImageFileProcessor().process(configuration: configuration).ensure {
                        PrimerAPIConfigurationModule.apiConfiguration?.clientSession = configuration.clientSession
                        PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules = configuration.checkoutModules
                        let cachedData = ConfigurationCachedData(config: configuration, headers: responseHeaders)
                        ConfigurationCache.shared.setData(cachedData, forKey: cacheKey)
                        seal.fulfill()
                    }
                case .failure(let err):
                    seal.reject(err)
                }
            }
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

    func storeRequiredActionClientToken(_ newClientToken: String) -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.validateClientToken(newClientToken, requestRemoteClientTokenValidation: true)
            }
            .done {
                PrimerAPIConfigurationModule.clientToken = newClientToken
                seal.fulfill()
            }
            .catch { err in
                PrimerAPIConfigurationModule.clientToken = nil
                PrimerAPIConfigurationModule.apiConfiguration = nil
                seal.reject(err)
            }
        }
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

    private func validateClientToken(_ clientToken: String, requestRemoteClientTokenValidation: Bool) -> Promise<Void> {
        return Promise { seal in
            do {
                _ = try validateClientTokenInternally(clientToken)
            } catch {
                seal.reject(error)
                return
            }

            let isAutoPaymentHandling = PrimerSettings.current.paymentHandling == .auto

            if !requestRemoteClientTokenValidation || isAutoPaymentHandling {
                AppState.current.clientToken = clientToken
                seal.fulfill()

            } else {
                firstly {
                    self.validateClientTokenRemotely(clientToken)
                }
                .done {
                    seal.fulfill()
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }

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

    private func validateClientTokenRemotely(_ clientToken: JWTToken) -> Promise<Void> {
        return Promise { seal in
            let clientTokenRequest = Request.Body.ClientTokenValidation(clientToken: clientToken)

            let apiClient: PrimerAPIClientProtocol = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
            apiClient.validateClientToken(request: clientTokenRequest) { result in
                switch result {
                case .success:
                    seal.fulfill()
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    private func validateClientTokenRemotely(_ clientToken: JWTToken) async throws {
        let clientTokenRequest = Request.Body.ClientTokenValidation(clientToken: clientToken)

        let apiClient: PrimerAPIClientProtocol = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
        _ = try await apiClient.validateClientToken(request: clientTokenRequest)
    }

    // swiftlint:disable:next function_body_length
    private func fetchConfiguration(requestDisplayMetadata: Bool) -> Promise<PrimerAPIConfiguration> {
        let start = Date().millisecondsSince1970
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken,
                  let cacheKey = Self.cacheKey else {
                return seal.reject(handled(primerError: .invalidClientToken()))
            }

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
                    seal.fulfill(cachedConfig.config)
                    return
                }

                if let pendingPromise = PrimerAPIConfigurationModule.pendingPromises[cacheKey as String] {
                    pendingPromise.done { config in
                        seal.fulfill(config)
                    }.catch { error in
                        seal.reject(error)
                    }
                    return
                }

                let promise = Promise<PrimerAPIConfiguration> { innerSeal in
                    let requestParameters = Request.URLParameters.Configuration(
                        skipPaymentMethodTypes: [],
                        requestDisplayMetadata: requestDisplayMetadata)

                    let apiClient: PrimerAPIClientProtocol = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
                    apiClient.fetchConfiguration(clientToken: clientToken, requestParameters: requestParameters) { (result, responseHeaders) in
                        switch result {
                        case .failure(let err):
                            innerSeal.reject(err)
                        case .success(let config):
                            _ = ImageFileProcessor().process(configuration: config).ensure {
                                // Cache the result
                                if self.cachingEnabled {
                                    let cachedData = ConfigurationCachedData(config: config, headers: responseHeaders)
                                    ConfigurationCache.shared.setData(cachedData, forKey: cacheKey)
                                }
                                self.recordLoadedEvent(start, source: .network)
                                innerSeal.fulfill(config)
                            }
                        }
                    }
                }

                PrimerAPIConfigurationModule.pendingPromises[cacheKey as String] = promise

                promise.done { config in
                    seal.fulfill(config)
                }.catch { error in
                    seal.reject(error)
                }

                _ = promise.ensure {
                    PrimerAPIConfigurationModule.queue.async {
                        PrimerAPIConfigurationModule.pendingPromises.removeValue(forKey: cacheKey as String)
                    }
                }
            }
        }
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

                if let pendingTask = PrimerAPIConfigurationModule.pendingTasks[cacheKey as String] {
                    Task {
                        do {
                            let config = try await pendingTask.wait()
                            continuation.resume(returning: config)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                    return
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

                PrimerAPIConfigurationModule.pendingTasks[cacheKey as String] = task

                Task {
                    do {
                        let config = try await task.wait()
                        continuation.resume(returning: config)
                    } catch {
                        continuation.resume(throwing: error)
                    }

                    PrimerAPIConfigurationModule.queue.async {
                        PrimerAPIConfigurationModule.pendingTasks.removeValue(forKey: cacheKey as String)
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
    ) -> Promise<PrimerAPIConfiguration> {
        if requestVaultedPaymentMethods {
            let vaultService: VaultServiceProtocol = VaultService(apiClient: PrimerAPIClient())
            let vaultedPaymentMethodsPromise = vaultService.fetchVaultedPaymentMethods()
            let fetchConfigurationPromise = self.fetchConfiguration(requestDisplayMetadata: true)

            return Promise { seal in
                firstly {
                    when(fulfilled: fetchConfigurationPromise, vaultedPaymentMethodsPromise)
                }
                .done { apiConfiguration, _ in
                    seal.fulfill(apiConfiguration)
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        } else {
            return self.fetchConfiguration(requestDisplayMetadata: requestDisplayMetadata)
        }
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
        let networksDescription = [CardNetwork].allowedCardNetworks.map { $0.rawValue }.joined(separator: ", ")
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
