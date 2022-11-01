//
//  PMFComponentStyle.swift
//  PrimerSDK
//
//  Created by Evangelos on 1/11/22.
//

#if canImport(UIKit)

import Foundation

extension PMF.Component {
    
    internal class ViewStyle: Codable {
        var margin: PMF.Component.ViewStyle.Margin?
        var textStyle: PMF.Component.Text.Style?
    }
}

extension PMF.Component.ViewStyle {
    
    internal class Margin: Codable {
        
        var leading: CGFloat?
        var top: CGFloat?
        var trailing: CGFloat?
        var bottom: CGFloat?
    }
}

extension PMF.Component.Text {
    
    internal enum Style: String, Codable {
        case title = "TITLE"
        case subtitle = "SUBTITLE"
    }
}

#endif
