//
//  PMFEventAction.swift
//  PrimerSDK
//
//  Created by Evangelos on 1/11/22.
//

#if canImport(UIKit)

import Foundation

extension PMF.Event.Action {
    
    internal enum `Type`: String, Codable {
        case navigate = "NAVIGATE"
    }
}

extension PMF.Event {
    
    internal class Action: Codable {
        
        var `type`: PMF.Event.Action.`Type`
        var screenId: String?
    }
}

#endif
