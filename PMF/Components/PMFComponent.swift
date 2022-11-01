//
//  PMFComponent.swift
//  PrimerSDK
//
//  Created by Evangelos on 1/11/22.
//

#if canImport(UIKit)

import Foundation

extension PMF.Component {
    
    internal enum ComponentType: String, Codable {
        case button = "BUTTON"
        case text = "TEXT"
        case textInput = "TEXT_INPUT"
    }
}

extension PMF {
    
    internal enum Component {
        
        case button(PMF.Component.Button)
        case text(PMF.Component.Text)
        case textInput(PMF.Component.TextInput)
    }
}

extension PMF.Component: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleContainer = try decoder.singleValueContainer()
        
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case ComponentType.button.rawValue:
            let buttonComponent = try singleContainer.decode(PMF.Component.Button.self)
            self = .button(buttonComponent)
            
        case ComponentType.text.rawValue:
            let textComponent = try singleContainer.decode(PMF.Component.Text.self)
            self = .text(textComponent)
            
        case ComponentType.textInput.rawValue:
            let textInputComponent = try singleContainer.decode(PMF.Component.TextInput.self)
            self = .textInput(textInputComponent)
            
        default:
            fatalError("Unknown type of content.")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var singleContainer = encoder.singleValueContainer()
        
        switch self {
        case .button(let buttonComponent):
            try singleContainer.encode(buttonComponent)
        case .text(let textComponent):
            try singleContainer.encode(textComponent)
        case .textInput(let textInputComponent):
            try singleContainer.encode(textInputComponent)
        }
    }
}

#endif
