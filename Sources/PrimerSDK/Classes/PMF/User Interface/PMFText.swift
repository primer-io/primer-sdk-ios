//
//  PMFText.swift
//  PrimerSDK
//
//  Created by Evangelos on 3/11/22.
//

#if canImport(UIKit)

import UIKit

extension PMF.UserInterface {
    
    class Text: UILabel {
        
        private let component: PMF.Component.Text
        private let params: [String: String?]?
        
        required init(textComponent: PMF.Component.Text, params: [String: String?]?) {
            self.component = textComponent
            self.params = params
            super.init(frame: .zero)
            
            if self.component.text.hasPrefix("{"),
               self.component.text.hasSuffix("}"),
               let val = self.params?[self.component.text.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")]
            {
                self.text = val
            } else {
                self.text = self.component.text
            }
            
            if #available(iOS 12.0, *) {
                if self.traitCollection.userInterfaceStyle == .dark {
                    self.textColor = PrimerColor(hex: self.component.style?.textColor?.dark ?? "#000000")
                } else {
                    self.textColor = PrimerColor(hex: self.component.style?.textColor?.light ?? "#000000")
                }
            } else {
                self.textColor = PrimerColor(hex: self.component.style?.textColor?.light ?? "#000000")
            }
            
            self.font = UIFont.systemFont(
                ofSize: self.component.style?.fontSize ?? 17.0,
                weight: UIFont.Weight(weight: self.component.style?.fontWeight ?? 400))
            
            if let textAlignment = self.component.style?.textAlignment {
                switch textAlignment {
                case .center:
                    self.textAlignment = .center
                case .end:
                    self.textAlignment = .right
                case .justify:
                    self.textAlignment = .justified
                case .start:
                    self.textAlignment = .left
                }
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

#endif
