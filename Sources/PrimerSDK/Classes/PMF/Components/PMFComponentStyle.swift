//
//  PMFComponentStyle.swift
//  PrimerSDK
//
//  Created by Evangelos on 1/11/22.
//

#if canImport(UIKit)

import Foundation

extension PMF.Component {
    
    internal class Style: Codable {
        
        // View props
        var aspectRatio: CGFloat?
        var backgroundColor: PMF.Component.Style.Color?
        var contentMode: PMF.Component.Style.ContentMode?
        var cornerRadius: CGFloat?
        var margin: CGFloat?
        var marginBottom: CGFloat?
        var marginEnd: CGFloat?
        var marginHorizontal: CGFloat?
        var marginStart: CGFloat?
        var marginTop: CGFloat?
        var marginVertical: CGFloat?
        var padding: CGFloat?
        var paddingBottom: CGFloat?
        var paddingEnd: CGFloat?
        var paddingHorizontal: CGFloat?
        var paddingStart: CGFloat?
        var paddingTop: CGFloat?
        var paddingVertical: CGFloat?
        var height: CGFloat?
        var width: CGFloat?
        
        // Text props
        var fontFamily: String?
        var fontSize: CGFloat?
        var fontWeight: CGFloat?
        var letterSpacing: CGFloat?
        var textAlignment: PMF.Component.Style.TextAlignment?
        var textColor: PMF.Component.Style.Color?
    }
}

extension PMF.Component.Style {
    
    class Color: Codable {
        
        let dark: String
        let light: String
    }
    
    enum ContentMode: String, Codable {
        
        case center = "CENTER"
        case fit = "FIT"
        case stretch = "STRETCH"
    }
    
    enum TextAlignment: String, Codable {
        
        case center = "CENTER"
        case end = "END"
        case justify = "JUSTIFY"
        case start = "START"
    }
}

#endif
