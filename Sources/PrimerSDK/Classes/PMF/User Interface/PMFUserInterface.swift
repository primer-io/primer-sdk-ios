//
//  PMFUserInterface.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/11/22.
//

#if canImport(UIKit)

import UIKit

extension PMF {
    
    class UserInterface {
        
        static func createView(for component: PMF.Component, with params: [String: String?]?) -> UIView? {
            switch component {
            case .button(let buttonComponent):
                let button = PMF.UserInterface.Button(buttonComponent: buttonComponent)
                return button
            case .container(let containerComponent):
                return PMF.UserInterface.Container(containerComponent: containerComponent, params: params)
            case .text(let textComponent):
                let label = PMF.UserInterface.Text(textComponent: textComponent, params: params)
                return label
            case .textInput(let textInputComponent):
                return PMF.UserInterface.TextInput(textInputComponent: textInputComponent)
            }
        }
        
        struct ViewStyle {
            
            var backgroundColor: UIColor?
            var cornerRadius: CGFloat?
            var height: CGFloat?
            var width: CGFloat?
        }
        
        struct TextStyle {
            
            var fontSize: CGFloat?
            var fontWeight: UIFont.Weight?
            var textColor: UIColor?
            var textAlignment: NSTextAlignment?
            
            static var largeTitle: PMF.UserInterface.TextStyle {
                return PMF.UserInterface.TextStyle(
                    fontSize: 34.0,
                    fontWeight: .regular,
                    textColor: .black,
                    textAlignment: nil)
            }
            
            static var title1: PMF.UserInterface.TextStyle {
                return PMF.UserInterface.TextStyle(
                    fontSize: 28.0,
                    fontWeight: .regular,
                    textColor: .black,
                    textAlignment: nil)
            }
            
            static var title2: PMF.UserInterface.TextStyle {
                return PMF.UserInterface.TextStyle(
                    fontSize: 22.0,
                    fontWeight: .regular,
                    textColor: .black,
                    textAlignment: nil)
            }
            
            static var title3: PMF.UserInterface.TextStyle {
                return PMF.UserInterface.TextStyle(
                    fontSize: 20.0,
                    fontWeight: .regular,
                    textColor: .black,
                    textAlignment: nil)
            }
            
            static var headline: PMF.UserInterface.TextStyle {
                return PMF.UserInterface.TextStyle(
                    fontSize: 17.0,
                    fontWeight: .semibold,
                    textColor: .black,
                    textAlignment: nil)
            }
            
            static var subHeadline: PMF.UserInterface.TextStyle {
                return PMF.UserInterface.TextStyle(
                    fontSize: 15.0,
                    fontWeight: .regular,
                    textColor: .black,
                    textAlignment: nil)
            }
            
            static var body: PMF.UserInterface.TextStyle {
                return PMF.UserInterface.TextStyle(
                    fontSize: 17.0,
                    fontWeight: .regular,
                    textColor: .black,
                    textAlignment: nil)
            }
            
            static var callout: PMF.UserInterface.TextStyle {
                return PMF.UserInterface.TextStyle(
                    fontSize: 16.0,
                    fontWeight: .regular,
                    textColor: .black,
                    textAlignment: nil)
            }
            
            static var footnote: PMF.UserInterface.TextStyle {
                return PMF.UserInterface.TextStyle(
                    fontSize: 13.0,
                    fontWeight: .regular,
                    textColor: .black,
                    textAlignment: nil)
            }
            
            static var caption1: PMF.UserInterface.TextStyle {
                return PMF.UserInterface.TextStyle(
                    fontSize: 12.0,
                    fontWeight: .regular,
                    textColor: .black,
                    textAlignment: nil)
            }
            
            static var caption2: PMF.UserInterface.TextStyle {
                return PMF.UserInterface.TextStyle(
                    fontSize: 11.0,
                    fontWeight: .regular,
                    textColor: .black,
                    textAlignment: nil)
            }
        }
        
    }
}

#endif
