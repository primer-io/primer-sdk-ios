//
//  PMFEvent.swift
//  PrimerSDK
//
//  Created by Evangelos on 1/11/22.
//

#if canImport(UIKit)

import Foundation

extension PMF.Event {
    
    internal enum `Type`: String, Codable {
        
        case onStart = "ON_START"
        case onError = "ON_ERROR"
        case onAdditionalDataReceived = "ON_ADDITIONAL_DATA_RECEIVED"
        case onRequiredActionReceived = "ON_REQUIRED_ACTION_RECEIVED"
    }
}

extension PMF {
    
    internal class Event: Codable {
        
        var type: PMF.Event.`Type`
        var action: PMF.Event.Action
    }
}

#endif
