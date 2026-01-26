//
//  AnalyticsEvent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation

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
            device: Device(),
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

extension NetworkCallEventProperties {
    fileprivate init(
        callType: Analytics.Event.Property.NetworkCallType,
        id: String,
        url: String,
        method: HTTPMethod,
        errorBody: String?,
        responseCode: Int?,
        duration: TimeInterval? = nil
    ) {
        var parameters: [String: AnyCodable]?
        let sdkProperties = SDKProperties()
        if let sdkPropertiesDict = try? sdkProperties.asDictionary(),
           let data = try? JSONSerialization.data(withJSONObject: sdkPropertiesDict, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: data) {
                parameters = anyDecodableDictionary
            }
        } else {
            parameters = nil
        }
        
        self.init(
            callType: callType,
            id: id,
            url: url,
            method: method.rawValue,
            errorBody: errorBody,
            responseCode: responseCode,
            params: parameters,
            duration: duration
        )
    }
}

extension NetworkConnectivityEventProperties {

    fileprivate init(networkType: Connectivity.NetworkType) {
        let sdkProperties = SDKProperties()
        var params: [String: AnyCodable]?
        if let sdkPropertiesDict = try? sdkProperties.asDictionary(),
           let data = try? JSONSerialization.data(withJSONObject: sdkPropertiesDict, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: data) {
                params = anyDecodableDictionary
            }
        }
        self.init(networkType: networkType.rawValue, params: params)
    }
}

extension SDKEventProperties {
    fileprivate init(name: String, params: [String: String]?) {
        var parameters: [String: Any] = params ?? [:]
        var finalParams: [String: AnyCodable]?
        let sdkProperties = SDKProperties()
        if let sdkPropertiesDict = try? sdkProperties.asDictionary() {
            parameters.merge(sdkPropertiesDict) {(current, _) in current}
        }

        if !parameters.isEmpty,
           let parametersData = try? JSONSerialization.data(withJSONObject: parameters, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: parametersData) {
                finalParams = anyDecodableDictionary
            }
        }
        self.init(name: name, parameters: finalParams)
    }
}

extension TimerEventProperties {
    fileprivate init(
        momentType: Analytics.Event.Property.TimerType,
        id: String?,
        duration: TimeInterval? = nil,
        context: [String: Any]? = nil
    ) {
        var params: [String: AnyCodable]?
        let sdkProperties = SDKProperties()
        if let sdkPropertiesDict = try? sdkProperties.asDictionary(),
           let data = try? JSONSerialization.data(withJSONObject: sdkPropertiesDict, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: data) {
                params = anyDecodableDictionary
            }
        }
        self.init(momentType: momentType, id: id, params: params, duration: duration, context: context)
    }
}

extension UIEventProperties {
    fileprivate init(
        action: Analytics.Event.Property.Action,
        context: Analytics.Event.Property.Context?,
        extra: String?,
        objectType: Analytics.Event.Property.ObjectType,
        objectId: Analytics.Event.Property.ObjectId?,
        objectClass: String?,
        place: Analytics.Event.Property.Place
    ) {
        var parameters: [String: String]?
        if let jsonData = try? JSONEncoder().encode(SDKProperties()),
           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments),
           let params = jsonObject as? [String: String] {
            parameters = params
        }
        
        self.init(
            action: action,
            context: context,
            extra: extra,
            objectType: objectType,
            objectId: objectId,
            objectClass: objectClass,
            place: place,
            params: parameters
        )
    }
}

extension SDKProperties {
    fileprivate init() {
        let integrationType: String
        #if COCOAPODS
        integrationType = "COCOAPODS"
        #else
        integrationType = "SPM"
        #endif
        
        var settingsData: [String: AnyCodable]?
        
        if let data = try? JSONEncoder().encode(PrimerSettings.current) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: data) {
                settingsData = anyDecodableDictionary
            }
        }
        
        self.init(
            clientToken: AppState.current.clientToken,
            integrationType: integrationType,
            paymentMethodType: PrimerInternal.shared.selectedPaymentMethodType,
            sdkIntegrationType: PrimerInternal.shared.sdkIntegrationType,
            sdkIntent: PrimerInternal.shared.intent,
            sdkPaymentHandling: PrimerSettings.current.paymentHandling,
            sdkSessionId: PrimerInternal.shared.checkoutSessionId,
            sdkSettings: settingsData,
            sdkType: Primer.shared.integrationOptions?.reactNativeVersion == nil ? "IOS_NATIVE" : "RN_IOS",
            sdkVersion: VersionUtils.releaseVersionNumber,
            context: nil
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

    static func message(message: String?,
                        messageType: Property.MessageType,
                        severity: Property.Severity,
                        diagnosticsId: String? = nil,
                        context: [String: Any]? = nil) -> Self {
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

    static func ui(action: Property.Action,
                   context: Property.Context?,
                   extra: String?,
                   objectType: Property.ObjectType,
                   objectId: Property.ObjectId?,
                   objectClass: String?,
                   place: Property.Place) -> Self {
        .init(
            eventType: .ui,
            properties: UIEventProperties(
                action: action,
                context: context,
                extra: extra,
                objectType: objectType,
                objectId: objectId,
                objectClass: objectClass,
                place: place)
        )
    }

    static func networkCall(callType: Property.NetworkCallType,
                            id: String,
                            url: String,
                            method: HTTPMethod,
                            errorBody: String?,
                            responseCode: Int?,
                            duration: TimeInterval? = nil) -> Self {
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

    static func networkConnectivity(
        networkType: Connectivity.NetworkType = Connectivity.networkType
    ) -> Self {
        .init(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(networkType: networkType.rawValue)
        )
    }

    static func timer(momentType: Property.TimerType,
                      id: String?,
                      duration: TimeInterval? = nil,
                      context: [String: Any]? = nil) -> Self {
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

    static func dropInLoading(duration: Int,
                              source: DropInLoadingSource) -> Self {
        .timer(momentType: .end,
               id: "DROP_IN_LOADING",
               duration: TimeInterval(duration),
               context: ["source": source.rawValue])
    }

    static func headlessLoading(duration: Int) -> Self {
        .timer(momentType: .end, id: "HEADLESS_LOADING", duration: TimeInterval(duration))
    }

    enum ConfigurationLoadingSource: String {
        case cache = "CACHE"
        case network = "NETWORK"
    }

    static func configurationLoading(duration: Int,
                                     source: ConfigurationLoadingSource) -> Self {
        .timer(momentType: .end, id: "CONFIGURATION_LOADING",
               duration: TimeInterval(duration),
               context: ["source": source.rawValue])
    }

    static func allImagesLoading(momentType: Property.TimerType,
                                 id: String?) -> Self {
        .init(
            eventType: .paymentMethodAllImagesLoading,
            properties: TimerEventProperties(
                momentType: momentType,
                id: id
            )
        )
    }

    static func imageLoading(momentType: Property.TimerType,
                             id: String?) -> Self {
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
