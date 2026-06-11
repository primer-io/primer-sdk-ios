//
//  AnalyticsEvent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking

// swiftlint:disable all
extension Analytics.Event {
    fileprivate init(
        eventType: Analytics.Event.EventType,
        properties: AnalyticsEventProperties?,
        analyticsUrl: String? = PrimerAPIConfigurationModule.decodedJWTToken?.analyticsUrlV2
    ) {
        self.init(
            analyticsUrl: analyticsUrl,
            localId: String.randomString(length: 32),
            appIdentifier: Bundle.main.bundleIdentifier,
            checkoutSessionId: PrimerInternal.shared.checkoutSessionId,
            clientSessionId: PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.clientSessionId,
            createdAt: Date().millisecondsSince1970,
            customerId: PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.customer?.id,
            device: Device(uniqueDeviceIdentifier: Device.deviceIdentifier),
            eventType: eventType,
            primerAccountId: PrimerAPIConfigurationModule.apiConfiguration?.primerAccountId,
            properties: properties,
            sdkSessionId: PrimerInternal.shared.sdkSessionId,
            sdkType: Primer.shared.integrationOptions?.reactNativeVersion == nil ? "IOS_NATIVE" : "RN_IOS",
            sdkVersion: VersionUtils.releaseVersionNumber,
            sdkIntegrationType: PrimerInternal.shared.sdkIntegrationType,
            sdkPaymentHandling: PrimerSettings.current.paymentHandling,
            integrationType: {
                #if COCOAPODS
                    return "COCOAPODS"
                #else
                    return "SPM"
                #endif
            }(),
            minDeploymentTarget: Bundle.main.minimumOSVersion ?? "Unknown"
        )
    }
}

extension Analytics.Event {

    static func sdk(name: String, params: [String: String]?) -> Self {
        .init(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: name,
                params: params
            )
        )
    }

    static func message(
        message: String?,
        messageType: Property.MessageType,
        severity: Property.Severity,
        diagnosticsId: String? = nil,
        context: [String: Any]? = nil
    ) -> Self {
        .init(
            eventType: .message,
            properties: MessageEventProperties(
                message: message,
                messageType: messageType,
                severity: severity,
                diagnosticsId: diagnosticsId,
                context: context
            )
        )
    }

    static func ui(
        action: Property.Action,
        context: Property.Context?,
        extra: String?,
        objectType: Property.ObjectType,
        objectId: Property.ObjectId?,
        objectClass: String?,
        place: Property.Place
    ) -> Self {
        .init(
            eventType: .ui,
            properties: UIEventProperties(
                action: action,
                context: context,
                extra: extra,
                objectType: objectType,
                objectId: objectId,
                objectClass: objectClass,
                place: place
            )
        )
    }

    static func networkCall(
        callType: Property.NetworkCallType,
        id: String,
        url: String,
        method: HTTPMethod,
        errorBody: String?,
        responseCode: Int?,
        duration: TimeInterval? = nil
    ) -> Self {
        .init(
            eventType: .networkCall,
            properties: NetworkCallEventProperties(
                callType: callType,
                id: id,
                url: url,
                method: method,
                errorBody: errorBody,
                responseCode: responseCode,
                duration: duration
            )
        )
    }

    static func networkConnectivity(networkType: Connectivity.NetworkType = Connectivity.networkType) -> Self {
        .init(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(networkType: networkType)
        )
    }

    static func appLifecycle(_ lifecycleType: AppLifecycleEventProperties.LifecycleType) -> Self {
        Analytics.Event(
            eventType: .appLifecycle,
            properties: AppLifecycleEventProperties(lifecycleType: lifecycleType)
        )
    }

    static func timer(
        momentType: Property.TimerType,
        id: String?,
        duration: TimeInterval? = nil,
        context: [String: Any]? = nil
    ) -> Self {
        .init(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: momentType,
                id: id,
                duration: duration,
                context: context
            )
        )
    }

    enum DropInLoadingSource: String {
        case universalCheckout = "UNIVERSAL_CHECKOUT"
        case showPaymentMethod = "SHOW_PAYMENT_METHOD"
        case vaultManager = "VAULT_MANAGER"
    }

    static func dropInLoading(
        duration: Int,
        source: DropInLoadingSource
    ) -> Self {
        .timer(
            momentType: .end,
            id: "DROP_IN_LOADING",
            duration: TimeInterval(duration),
            context: ["source": source.rawValue]
        )
    }

    static func headlessLoading(duration: Int) -> Self {
        .timer(momentType: .end, id: "HEADLESS_LOADING", duration: TimeInterval(duration))
    }

    enum ConfigurationLoadingSource: String {
        case cache = "CACHE"
        case network = "NETWORK"
    }

    static func configurationLoading(
        duration: Int,
        source: ConfigurationLoadingSource
    ) -> Self {
        .timer(
            momentType: .end,
            id: "CONFIGURATION_LOADING",
            duration: TimeInterval(duration),
            context: ["source": source.rawValue]
        )
    }

    static func allImagesLoading(
        momentType: Property.TimerType,
        id: String?
    ) -> Self {
        .init(
            eventType: .paymentMethodAllImagesLoading,
            properties: TimerEventProperties(
                momentType: momentType,
                id: id
            )
        )
    }

    static func imageLoading(
        momentType: Property.TimerType,
        id: String?
    ) -> Self {
        .init(
            eventType: .paymentMethodImageLoading,
            properties: TimerEventProperties(
                momentType: momentType,
                id: id
            )
        )
    }
}
// swiftlint:enable all
