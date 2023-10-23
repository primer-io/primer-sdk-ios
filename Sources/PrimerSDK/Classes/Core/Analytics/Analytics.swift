//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//



import Foundation

class Analytics {
    
    static let queue: DispatchQueue = DispatchQueue(label: "primer.analytics", qos: .utility)
    static var apiClient: PrimerAPIClientProtocol?
    
    struct Event: Codable, Equatable {
        
        static func == (lhs: Analytics.Event, rhs: Analytics.Event) -> Bool {
            return lhs.localId == rhs.localId
        }
                
        let analyticsUrl: String?
        let localId: String
        let appIdentifier: String?
        let checkoutSessionId: String?
        let clientSessionId: String?
        var createdAt: Int  // 👈 `createdAt` will be modified and get the error's timestamp for error events.
        let customerId: String?
        let device: Device
        let eventType: Analytics.Event.EventType
        let primerAccountId: String?
        var properties: AnalyticsEventProperties?  // 👈 `properties` can be modified.
        let sdkSessionId: String
        let sdkType: String
        let sdkVersion: String?
        let sdkIntegrationType: PrimerSDKIntegrationType?
        let sdkPaymentHandling: PrimerPaymentHandling?
        let integrationType: String
        let minDeploymentTarget: String
        
        init(eventType: Analytics.Event.EventType, properties: AnalyticsEventProperties?) {
            self.analyticsUrl = PrimerAPIConfigurationModule.decodedJWTToken?.analyticsUrlV2
            self.localId = String.randomString(length: 32)
            
            self.appIdentifier = Bundle.main.bundleIdentifier
            self.checkoutSessionId = PrimerInternal.shared.checkoutSessionId
            self.clientSessionId = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.clientSessionId
            self.createdAt = Date().millisecondsSince1970
            self.customerId = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.customer?.id
            self.device = Device()
            self.eventType = eventType
            self.primerAccountId = PrimerAPIConfigurationModule.apiConfiguration?.primerAccountId
            self.properties = properties
            self.sdkSessionId = PrimerInternal.shared.sdkSessionId
            self.sdkType = Primer.shared.integrationOptions?.reactNativeVersion == nil ? "IOS_NATIVE" : "RN_IOS"
            self.sdkVersion = VersionUtils.releaseVersionNumber
            self.sdkIntegrationType = PrimerInternal.shared.sdkIntegrationType
            self.sdkPaymentHandling = PrimerSettings.current.paymentHandling
            self.minDeploymentTarget = Bundle.main.minimumOSVersion ?? "Unknown"
            
#if COCOAPODS
            self.integrationType = "COCOAPODS"
#else
            self.integrationType = "SPM"
#endif
        }
        
        private enum CodingKeys: String, CodingKey {
            case analyticsUrl,
                 localId,
                 appIdentifier,
                 checkoutSessionId,
                 clientSessionId,
                 createdAt,
                 customerId,
                 device,
                 eventType,
                 primerAccountId,
                 properties,
                 sdkSessionId,
                 sdkType,
                 sdkVersion,
                 sdkIntegrationType,
                 sdkPaymentHandling,
                 integrationType,
                 minDeploymentTarget
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(analyticsUrl, forKey: .analyticsUrl)
            try? container.encode(appIdentifier, forKey: .appIdentifier)
            try? container.encode(checkoutSessionId, forKey: .checkoutSessionId)
            try? container.encode(clientSessionId, forKey: .clientSessionId)
            try? container.encode(createdAt, forKey: .createdAt)
            try? container.encode(customerId, forKey: .customerId)
            try? container.encode(device, forKey: .device)
            try? container.encode(eventType, forKey: .eventType)
            try? container.encode(localId, forKey: .localId)
            try? container.encode(primerAccountId, forKey: .primerAccountId)
            try? container.encode(sdkSessionId, forKey: .sdkSessionId)
            try? container.encode(sdkType, forKey: .sdkType)
            try? container.encode(sdkVersion, forKey: .sdkVersion)
            try? container.encode(sdkIntegrationType?.rawValue, forKey: .sdkIntegrationType)
            try? container.encode(integrationType, forKey: .integrationType)
            try? container.encode(minDeploymentTarget, forKey: .minDeploymentTarget)
            
            if sdkPaymentHandling == .auto {
                try? container.encode("AUTO", forKey: .sdkPaymentHandling)
            } else if sdkPaymentHandling == .manual {
                try? container.encode("MANUAL", forKey: .sdkPaymentHandling)
            }
            
            if let crashEventProperties = properties as? CrashEventProperties {
                try? container.encode(crashEventProperties, forKey: .properties)
            } else if let messageEventProperties = properties as? MessageEventProperties {
                try? container.encode(messageEventProperties, forKey: .properties)
            } else if let networkCallEventProperties = properties as? NetworkCallEventProperties {
                try? container.encode(networkCallEventProperties, forKey: .properties)
            } else if let networkConnectivityEventProperties = properties as? NetworkConnectivityEventProperties {
                try? container.encode(networkConnectivityEventProperties, forKey: .properties)
            } else if let sdkEventProperties = properties as? SDKEventProperties {
                try? container.encode(sdkEventProperties, forKey: .properties)
            } else if let timerEventProperties = properties as? TimerEventProperties {
                try? container.encode(timerEventProperties, forKey: .properties)
            } else if let uiEventProperties = properties as? UIEventProperties {
                try? container.encode(uiEventProperties, forKey: .properties)
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.analyticsUrl = try container.decodeIfPresent(String.self, forKey: .analyticsUrl)
            self.appIdentifier = try container.decodeIfPresent(String.self, forKey: .appIdentifier)
            self.checkoutSessionId = try container.decodeIfPresent(String.self, forKey: .checkoutSessionId)
            self.clientSessionId = try container.decodeIfPresent(String.self, forKey: .clientSessionId)
            self.createdAt = try container.decode(Int.self, forKey: .createdAt)
            self.customerId = try container.decodeIfPresent(String.self, forKey: .customerId)
            self.device = try container.decode(Device.self, forKey: .device)
            self.eventType = try container.decode(Analytics.Event.EventType.self, forKey: .eventType)
            self.localId = try container.decode(String.self, forKey: .localId)
            self.primerAccountId = try container.decodeIfPresent(String.self, forKey: .primerAccountId)
            self.sdkSessionId = try container.decode(String.self, forKey: .sdkSessionId)
            self.sdkType = try container.decode(String.self, forKey: .sdkType)
            self.sdkVersion = try container.decode(String.self, forKey: .sdkVersion)
            self.integrationType = try container.decode(String.self, forKey: .integrationType)
            self.minDeploymentTarget = try container.decode(String.self, forKey: .minDeploymentTarget)
            
            if let sdkIntegrationTypeStr = try? container.decode(String.self, forKey: .sdkIntegrationType) {
                self.sdkIntegrationType = PrimerSDKIntegrationType(rawValue: sdkIntegrationTypeStr)
            } else {
                self.sdkIntegrationType = nil
            }
            
            if let sdkPaymentHandlingStr = try? container.decode(String.self, forKey: .sdkPaymentHandling) {
                if sdkPaymentHandlingStr == "AUTO" {
                    self.sdkPaymentHandling = .auto
                } else if sdkPaymentHandlingStr == "MANUAL" {
                    self.sdkPaymentHandling = .manual
                } else {
                    self.sdkPaymentHandling = nil
                }
            } else {
                self.sdkPaymentHandling = nil
            }
            
            if let crashEventProperties = (try? container.decode(CrashEventProperties?.self, forKey: .properties)) {
                self.properties = crashEventProperties
            } else if let messageEventProperties = (try? container.decode(MessageEventProperties?.self, forKey: .properties)) {
                self.properties = messageEventProperties
            } else if let networkCallEventProperties = (try? container.decode(NetworkCallEventProperties?.self, forKey: .properties)) {
                self.properties = networkCallEventProperties
            } else if let networkConnectivityEventProperties = (try? container.decode(NetworkConnectivityEventProperties?.self, forKey: .properties)) {
                self.properties = networkConnectivityEventProperties
            } else if let sdkEventProperties = (try? container.decode(SDKEventProperties?.self, forKey: .properties)) {
                self.properties = sdkEventProperties
            } else if let timerEventProperties = (try? container.decode(TimerEventProperties?.self, forKey: .properties)) {
                self.properties = timerEventProperties
            } else if let uiEventProperties = (try? container.decode(UIEventProperties?.self, forKey: .properties)) {
                self.properties = uiEventProperties
            } else {
                self.properties = nil
            }
        }
    }
}


