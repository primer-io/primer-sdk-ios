//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

#if canImport(UIKit)

import Foundation

class Analytics {
    
    static let queue: DispatchQueue = DispatchQueue(label: "primer.analytics")
    static var apiClient: PrimerAPIClientProtocol?
    
    struct Event: Codable {
        // The variables below are used locally, and are getting deleted before sending them.
        var analyticsUrl: String?
        var localId: String?
        
        var appIdentifier: String? = Bundle.main.bundleIdentifier
        var checkoutSessionId: String?
        var clientSessionId: String?
        var createdAt: Int = Date().millisecondsSince1970
        var customerId: String?
        var device: Device = Device()
        var eventType: Analytics.Event.EventType
        var primerAccountId: String?
        var properties: AnalyticsEventProperties? = nil
        var sdkSessionId: String
        var sdkType: String = PrimerSource.iOSNative.sourceType
        var sdkVersion = Bundle.primerFramework.releaseVersionNumber
        
        init(eventType: Analytics.Event.EventType, properties: AnalyticsEventProperties?) {
            self.eventType = eventType
            self.properties = properties
            self.analyticsUrl = PrimerAPIConfigurationModule.decodedJWTToken?.analyticsUrl
            self.checkoutSessionId = PrimerInternal.shared.checkoutSessionId
            self.clientSessionId = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.clientSessionId
            self.customerId = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.customer?.id
            self.localId = String.randomString(length: 32)
            self.sdkSessionId = PrimerInternal.shared.sdkSessionId
        }
        
        private enum CodingKeys: String, CodingKey {
            case analyticsUrl, appIdentifier, checkoutSessionId, clientSessionId,
                 createdAt, customerId, device, eventType, localId, primerAccountId,
                 properties, sdkSessionId, sdkType, sdkVersion
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
            if let localId = localId {
                try? container.encode(localId, forKey: .localId)
            }
            try? container.encode(primerAccountId, forKey: .primerAccountId)
            try? container.encode(sdkSessionId, forKey: .sdkSessionId)
            try? container.encode(sdkType, forKey: .sdkType)
            try? container.encode(sdkVersion, forKey: .sdkVersion)
            
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
            self.analyticsUrl = (try? container.decode(String?.self, forKey: .analyticsUrl)) ?? nil
            self.appIdentifier = (try? container.decode(String.self, forKey: .appIdentifier)) ?? nil
            self.checkoutSessionId = (try? container.decode(String?.self, forKey: .checkoutSessionId)) ?? nil
            self.clientSessionId = (try? container.decode(String?.self, forKey: .clientSessionId)) ?? nil
            self.createdAt = try container.decode(Int.self, forKey: .createdAt)
            self.customerId = (try container.decode(String?.self, forKey: .customerId)) ?? nil
            self.device = try container.decode(Device.self, forKey: .device)
            self.eventType = try container.decode(Analytics.Event.EventType.self, forKey: .eventType)
            self.localId = (try? container.decode(String?.self, forKey: .localId)) ?? nil
            self.primerAccountId = (try? container.decode(String?.self, forKey: .primerAccountId)) ?? nil
            self.sdkSessionId = try container.decode(String.self, forKey: .sdkSessionId)
            self.sdkType = try container.decode(String.self, forKey: .sdkType)
            self.sdkVersion = try container.decode(String.self, forKey: .sdkVersion)
            
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
            }
        }
        
    }
    
}

#endif
