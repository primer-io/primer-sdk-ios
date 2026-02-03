//
//  Event.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public extension Analytics {
    
    struct Event: Codable, Equatable {
        
        public static func == (lhs: Analytics.Event, rhs: Analytics.Event) -> Bool {
            lhs.localId == rhs.localId
        }
        
        public let analyticsUrl: String?
        public let localId: String
        public let appIdentifier: String?
        public let checkoutSessionId: String?
        public let clientSessionId: String?
        public var createdAt: Int  // 👈 `createdAt` will be modified and get the error's timestamp for error events.
        public let customerId: String?
        public let device: Device
        public let eventType: Analytics.Event.EventType
        public let primerAccountId: String?
        public var properties: AnalyticsEventProperties?  // 👈 `properties` can be modified.
        public let sdkSessionId: String
        public let sdkType: String
        public let sdkVersion: String?
        public let sdkIntegrationType: PrimerSDKIntegrationType?
        public let sdkPaymentHandling: PrimerPaymentHandling?
        public let integrationType: String
        public let minDeploymentTarget: String
        
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
        
        public init(
            analyticsUrl: String?,
            localId: String,
            appIdentifier: String?,
            checkoutSessionId: String?,
            clientSessionId: String?,
            createdAt: Int,
            customerId: String?,
            device: Device,
            eventType: Analytics.Event.EventType,
            primerAccountId: String?,
            properties: AnalyticsEventProperties?,
            sdkSessionId: String,
            sdkType: String,
            sdkVersion: String?,
            sdkIntegrationType: PrimerSDKIntegrationType?,
            sdkPaymentHandling: PrimerPaymentHandling?,
            integrationType: String,
            minDeploymentTarget: String
        ) {
            self.analyticsUrl = analyticsUrl
            self.localId = localId
            self.appIdentifier = appIdentifier
            self.checkoutSessionId = checkoutSessionId
            self.clientSessionId = clientSessionId
            self.createdAt = createdAt
            self.customerId = customerId
            self.device = device
            self.eventType = eventType
            self.primerAccountId = primerAccountId
            self.properties = properties
            self.sdkSessionId = sdkSessionId
            self.sdkType = sdkType
            self.sdkVersion = sdkVersion
            self.sdkIntegrationType = sdkIntegrationType
            self.sdkPaymentHandling = sdkPaymentHandling
            self.integrationType = integrationType
            self.minDeploymentTarget = minDeploymentTarget
        }
        
        public func encode(to encoder: Encoder) throws {
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
            
            if let messageEventProperties = properties as? MessageEventProperties {
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
        
        public init(from decoder: Decoder) throws {
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
            
            if let messageEventProperties = (try? container.decode(MessageEventProperties?.self, forKey: .properties)) {
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
