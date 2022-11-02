//
//  PMFComponentInput.swift
//  PrimerSDK
//
//  Created by Evangelos on 1/11/22.
//

#if canImport(UIKit)

import UIKit

extension PMF.Component {
    
    class TextInput: Codable {
        
        var allowedCharacters: String?
        var keyboardType: String
        var placeholder: String?
        var style: PMF.Component.ViewStyle
        var validation: String?
        
        private enum CodingKeys : String, CodingKey {
            case allowedCharacters, keyboardType, placeholder, style, validation
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.allowedCharacters = try container.decode(String?.self, forKey: .allowedCharacters)
            self.keyboardType = try container.decode(String.self, forKey: .keyboardType)
            self.placeholder = try container.decode(String?.self, forKey: .placeholder)
            self.style = try container.decode(PMF.Component.ViewStyle.self, forKey: .style)
            self.validation = try container.decode(String?.self, forKey: .validation)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.allowedCharacters, forKey: .allowedCharacters)
            try container.encode(self.keyboardType, forKey: .keyboardType)
            try container.encode(self.placeholder, forKey: .placeholder)
            try container.encode(self.style, forKey: .style)
            try container.encode(self.validation, forKey: .validation)
        }
    }
}

#endif
