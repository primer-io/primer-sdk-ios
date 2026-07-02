//
//  ComponentsAnalyticsLoggingBridge.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@_spi(PrimerInternal)
public final class ComponentsAnalyticsLoggingBridge: LogReporter {

    private static let vaultMetadataKeys: Set<String> = [
        "vaultedMethodId", "previousVaultedMethodId", "promotedVaultedMethodId",
        "isActive", "vaultedMethodCount", "exitedFromConfirmation",
        "network", "expectedCvvLength", "errorId",
    ]

    private let analyticsService: CheckoutComponentsAnalyticsServiceProtocol
    private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol
    private let loggingService: any ComponentsLoggingServiceProtocol
    private let configurationModule: AnalyticsSessionConfigProviding

    public init() {
        let analyticsService = AnalyticsEventService.create(
            environmentProvider: AnalyticsEnvironmentProvider()
        )
        self.analyticsService = analyticsService
        analyticsInteractor = DefaultAnalyticsInteractor(eventService: analyticsService)
        loggingService = LoggingService(
            networkClient: LogNetworkClient(),
            payloadBuilder: LogPayloadBuilder()
        )
        configurationModule = PrimerAPIConfigurationModule()
    }

    init(
        analyticsService: CheckoutComponentsAnalyticsServiceProtocol,
        analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol,
        loggingService: any ComponentsLoggingServiceProtocol,
        configurationModule: AnalyticsSessionConfigProviding
    ) {
        self.analyticsService = analyticsService
        self.analyticsInteractor = analyticsInteractor
        self.loggingService = loggingService
        self.configurationModule = configurationModule
    }

    // MARK: - Setup

    public func setup(clientToken: String) async {
        await LoggingSessionContext.shared.initialize(
            clientToken: clientToken,
            integrationType: .reactNative
        )

        guard let config = configurationModule.makeAnalyticsSessionConfig(
            checkoutSessionId: PrimerInternal.shared.checkoutSessionId ?? UUID().uuidString,
            clientToken: clientToken,
            sdkVersion: VersionUtils.releaseVersionNumber ?? "unknown"
        ) else {
            return
        }

        await analyticsService.initialize(config: config)
    }

    // MARK: - Analytics

    public func trackEvent(_ eventName: String, metadata: [String: String]?) async {
        guard let eventType = AnalyticsEventType(rawValue: eventName) else {
            logger.debug(message: "[Analytics] Dropping unknown event name: \(eventName)")
            return
        }
        await analyticsInteractor.trackEvent(eventType, metadata: Self.mapMetadata(metadata, for: eventType))
    }

    // MARK: - Logging

    public func logInfo(message: String, event: String, userInfo: [String: Any]? = nil) async {
        await loggingService.logInfo(message: message, event: event, userInfo: userInfo)
    }

    public func logError(
        message: String,
        event: String? = nil,
        errorMessage: String? = nil,
        stack: String? = nil,
        userInfo: [String: Any]? = nil
    ) async {
        await loggingService.logError(
            message: message,
            event: event,
            errorMessage: errorMessage,
            stack: stack,
            userInfo: userInfo
        )
    }

    // MARK: - Metadata Mapping

    /// Maps the RN string dictionary into typed metadata. Empty strings degrade to nil; Bool/Int
    /// values must be exactly `"true"`/`"false"`/integer strings — anything else degrades to nil.
    static func mapMetadata(
        _ metadata: [String: String]?,
        for eventType: AnalyticsEventType
    ) -> AnalyticsEventMetadata {
        if eventType.isVaultEvent {
            if let metadata {
                let unconsumed = Set(metadata.keys).subtracting(vaultMetadataKeys)
                if !unconsumed.isEmpty {
                    logger.debug(
                        message: "[Analytics] Dropping unconsumed vault metadata keys: \(unconsumed.sorted())"
                    )
                }
            }
            let value: (String) -> String? = { key in
                metadata?[key].flatMap { $0.isEmpty ? nil : $0 }
            }
            return .vault(VaultEvent(
                vaultedMethodId: value("vaultedMethodId"),
                previousVaultedMethodId: value("previousVaultedMethodId"),
                promotedVaultedMethodId: value("promotedVaultedMethodId"),
                isActive: metadata?["isActive"].flatMap(Bool.init),
                vaultedMethodCount: metadata?["vaultedMethodCount"].flatMap(Int.init),
                exitedFromConfirmation: metadata?["exitedFromConfirmation"].flatMap(Bool.init),
                network: value("network"),
                expectedCvvLength: metadata?["expectedCvvLength"].flatMap(Int.init),
                errorId: value("errorId")
            ))
        }

        guard let metadata else { return .general() }

        guard let paymentMethod = metadata["paymentMethod"], !paymentMethod.isEmpty else {
            return .general()
        }

        if let provider = metadata["threedsProvider"] {
            return .threeDS(ThreeDSEvent(paymentMethod: paymentMethod, provider: provider))
        }

        if let url = metadata["redirectDestinationUrl"] {
            return .redirect(RedirectEvent(paymentMethod: paymentMethod, destinationUrl: url))
        }

        return .payment(PaymentEvent(paymentMethod: paymentMethod, paymentId: metadata["paymentId"]))
    }
}
