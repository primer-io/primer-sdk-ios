//
//  PMFText.swift
//  Pods-ExampleApp
//
//  Created by Evangelos on 1/11/22.
//

#if canImport(UIKit)

import UIKit

extension PMF.Component {
    
    class Text: Codable {
        
        var text: String
        var style: PMF.Component.ViewStyle
        
        private enum CodingKeys : String, CodingKey {
            case text, style
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.text = try container.decode(String.self, forKey: .text)
            self.style = try container.decode(PMF.Component.ViewStyle.self, forKey: .style)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.text, forKey: .text)
            try container.encode(self.style, forKey: .style)
        }
    }
}

#endif
