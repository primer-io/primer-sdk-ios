//
//  PMFComponentButton.swift
//  PrimerSDK
//
//  Created by Evangelos on 1/11/22.
//

#if canImport(UIKit)

import UIKit

extension PMF.Component.Button {
    
    internal enum ButtonType: String, Codable {
        case `default` = "DEFAULT"
        case pay = "PAY"
    }
}

extension PMF.Component {
    
    class Button: Codable {
        
        var style: PMF.Component.Style?
        var text: String
        var clickAction: PMF.Component.Click.Action
        
        var onStartFlow: (() -> Void)?
        var onDismiss: (() -> Void)?
        
        private enum CodingKeys : String, CodingKey {
            case style
            case text
            case clickAction = "onClickAction"
        }
        
        required init(from decoder: Decoder) throws {
            do {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.clickAction = try container.decode(PMF.Component.Click.Action.self, forKey: .clickAction)
                self.style = (try? container.decode(PMF.Component.Style?.self, forKey: .style)) ?? nil
                self.text = try container.decode(String.self, forKey: .text)
            } catch {
                throw error
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.clickAction, forKey: .clickAction)
            try container.encode(self.style, forKey: .style)
            try container.encode(self.text, forKey: .text)
        }
    }
}

#endif
