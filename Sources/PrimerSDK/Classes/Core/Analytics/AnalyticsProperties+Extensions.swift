//
//  AnalyticsProperties+Extensions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerNetworking

extension NetworkCallEventProperties {
    init(
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

extension AppLifecycleEventProperties {
    init(lifecycleType: LifecycleType) {
        let sdkProperties = SDKProperties()
        let dict = try? sdkProperties.asDictionary()
        let data = try? JSONSerialization.data(withJSONObject: dict as Any, options: .fragmentsAllowed)
        let params = data.flatMap { try? JSONDecoder().decode([String: AnyCodable].self, from: $0) }
        self.init(lifecycleType: lifecycleType, params: params)
    }
}

extension NetworkConnectivityEventProperties {
    init(networkType: Connectivity.NetworkType) {
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
    init(name: String, params: [String: String]?) {
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
    init(
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
    init(
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
    init() {
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
