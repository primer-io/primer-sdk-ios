//
//  PMFText.swift
//  Pods-ExampleApp
//
//  Created by Evangelos on 1/11/22.
//

#if canImport(UIKit)

import Foundation

extension PMF.Component {
    
    class Text: Codable {
        
        var text: String
        var style: PMF.Component.Style?
        
        private enum CodingKeys : String, CodingKey {
            case style, text
        }
        
        required init(from decoder: Decoder) throws {
            do {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.style = (try? container.decode(PMF.Component.Style?.self, forKey: .style)) ?? nil
                self.text = try container.decode(String.self, forKey: .text)
            } catch {
                print(error)
                throw error
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.style, forKey: .style)
            try container.encode(self.text, forKey: .text)
        }
    }
}

#endif
