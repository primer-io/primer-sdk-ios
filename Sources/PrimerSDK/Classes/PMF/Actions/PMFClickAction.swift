//
//  PMFClickAction.swift
//  PrimerSDK
//
//  Created by Evangelos on 1/11/22.
//

#if canImport(UIKit)

import Foundation

extension PMF.Component {
    
    internal class Click {}
}

extension PMF.Component.Click.Action {
    
    internal enum `Type`: String, Codable {
        case startFlow = "START_FLOW"
        case dismiss = "DISMISS"
    }
}

extension PMF.Component.Click {
    
    internal class Action: Codable {
        var `type`: PMF.Component.Click.Action.`Type`
    }
}

#endif
