//
//  PMFButton.swift
//  PrimerSDK
//
//  Created by Evangelos on 3/11/22.
//

#if canImport(UIKit)

import UIKit

extension PMF.UserInterface {
    
    class Button: UIButton {
        
        var component: PMF.Component.Button
        private(set) var isLoading: Bool = false
        private var activityIndicator: UIActivityIndicatorView!
        
        override var intrinsicContentSize: CGSize {
            var size = super.intrinsicContentSize
            
            if let height = self.component.style?.height {
                size.height = height
            }
            
            if let width = self.component.style?.width {
                size.width = width
            }
            
            return size
        }
        
        required init(buttonComponent: PMF.Component.Button) {
            self.component = buttonComponent
            super.init(frame: .zero)
            
            self.setTitle(self.component.text, for: .normal)
            self.addTarget(self, action: #selector(self.buttonTapped(_:)), for: .touchUpInside)
            
            if let backgroundColor = self.component.style?.backgroundColor {
                if #available(iOS 12.0, *) {
                    if self.traitCollection.userInterfaceStyle == .dark {
                        self.backgroundColor = PrimerColor(hex: backgroundColor.dark) ?? .clear
                    } else {
                        self.backgroundColor = PrimerColor(hex: backgroundColor.light) ?? .clear
                    }
                } else {
                    self.backgroundColor = PrimerColor(hex: backgroundColor.light) ?? .clear
                }
            } else {
                self.backgroundColor = .clear
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func draw(_ rect: CGRect) {
            super.draw(rect)
            
            if let cornerRadius = self.component.style?.cornerRadius {
                self.layer.cornerRadius = cornerRadius
                self.clipsToBounds = true
            }
            
            if let textColor = self.component.style?.textColor {
                if #available(iOS 12.0, *) {
                    if self.traitCollection.userInterfaceStyle == .dark {
                        self.setTitleColor(PrimerColor(hex: textColor.dark) ?? .white, for: .normal)
                    } else {
                        self.setTitleColor(PrimerColor(hex: textColor.light) ?? .black, for: .normal)
                    }
                } else {
                    self.setTitleColor(PrimerColor(hex: textColor.light) ?? .black, for: .normal)
                }
            }
            
            let font = UIFont.systemFont(
                ofSize: self.component.style?.fontSize ?? 17.0,
                weight: UIFont.Weight(weight: self.component.style?.fontWeight ?? 400))
            
            self.titleLabel?.font = font
        }
        
        @objc
        private func buttonTapped(_ sender: PMF.UserInterface.Button) {
            switch self.component.clickAction.type {
            case .startPaymentFlow:
                self.setIsLoading(true)
                self.component.onStartFlow?()
                
            case .dismiss:
                self.component.onDismiss?()
            }
        }
        
        func setIsLoading(_ isLoading: Bool) {
            if isLoading {
                self.setTitle("", for: .normal)
                
                if (activityIndicator == nil) {
                    self.activityIndicator = UIActivityIndicatorView()
                    self.activityIndicator.hidesWhenStopped = true
                    self.activityIndicator.color = .lightGray
                }
                
                self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(self.activityIndicator)
                let xCenterConstraint = NSLayoutConstraint(
                    item: self,
                    attribute: .centerX,
                    relatedBy: .equal,
                    toItem: self.activityIndicator,
                    attribute: .centerX,
                    multiplier: 1,
                    constant: 0)
                self.addConstraint(xCenterConstraint)
                
                let yCenterConstraint = NSLayoutConstraint(
                    item: self,
                    attribute: .centerY,
                    relatedBy: .equal,
                    toItem: self.activityIndicator,
                    attribute: .centerY,
                    multiplier: 1,
                    constant: 0)
                self.addConstraint(yCenterConstraint)
                self.activityIndicator.startAnimating()
                
            } else {
                self.setTitle(self.component.text, for: .normal)
                self.activityIndicator.stopAnimating()
                self.activityIndicator.removeFromSuperview()
            }
            
            self.isLoading = isLoading
        }
        
        func setIsEnabled(_ isEnabled: Bool) {
            self.isEnabled = isEnabled
        }
        
        
        
        
        
        
        
        
        
        
        
        
        enum Style {
            case `default`, pay
            
            var viewStyle: PMF.UserInterface.ViewStyle {
                switch self {
                case .pay:
                    return PMF.UserInterface.ViewStyle(
                        backgroundColor: UIColor.black,
                        cornerRadius: 10.0,
                        height: 48.0,
                        width: nil)
                    
                default:
                    return PMF.UserInterface.ViewStyle(
                        backgroundColor: UIColor.systemBlue,
                        cornerRadius: 10.0,
                        height: 48.0,
                        width: nil)
                }
            }
            
            var textStyle: PMF.UserInterface.TextStyle {
                switch self {
                case .pay:
                    return PMF.UserInterface.TextStyle(
                        fontSize: 17.0,
                        fontWeight: .semibold,
                        textColor: UIColor.white)
                    
                default:
                    return PMF.UserInterface.TextStyle(
                        fontSize: 17.0,
                        fontWeight: .regular,
                        textColor: UIColor.white)
                }
            }
        }
    }
}

#endif
