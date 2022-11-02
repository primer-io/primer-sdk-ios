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
        
        var buttonType: PMF.Component.Button.ButtonType
        var text: String
        var clickAction: PMF.Component.Click.Action
        
        private enum CodingKeys : String, CodingKey {
            case buttonType
            case text
            case clickAction = "onClickAction"
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.buttonType = try container.decode(PMF.Component.Button.ButtonType.self, forKey: .buttonType)
            self.text = try container.decode(String.self, forKey: .text)
            self.clickAction = try container.decode(PMF.Component.Click.Action.self, forKey: .clickAction)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.buttonType, forKey: .buttonType)
            try container.encode(self.text, forKey: .text)
            try container.encode(self.clickAction, forKey: .clickAction)
        }
    }
}

#endif
