//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

#if canImport(UIKit)

import Foundation

class Analytics {
    
    struct Event: Codable {
        
        let appIdentifier = Bundle.main.bundleIdentifier
        var checkoutSessionId: String?
        var clientSessionId: String?
        var createdAt: Int = Date().millisecondsSince1970
        var customerId: String?
        var device: Device = Device()
        var eventType: Analytics.Event.`Type`
        var isSynced: Bool = false
        var primerAccountId: String?
        var properties: [String: String]?
        let sdkType: String = "IOS_NATIVE"
        let sdkVersion = Bundle.primerFramework.releaseVersionNumber
        
        
        init(
            eventType: Analytics.Event.`Type`,
            properties: Properties?
        ) {
            self.eventType = eventType
            
            if let checkoutSessionId = Primer.shared.checkoutSessionId {
                self.checkoutSessionId = checkoutSessionId
            }
            
            let state: AppStateProtocol = DependencyContainer.resolve()
            if let config = state.primerConfiguration, let clientSessionId = config.clientSession?.clientSessionId {
                self.clientSessionId = clientSessionId
            }
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            if let customerId = settings.customerId {
                self.customerId = customerId
            }
            
            self.properties = properties?.jsonValue
        }
        
    }
    
}

#endif
