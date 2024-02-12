//
//  UIViewExtensions.swift
//  PrimerScannerDemo
//
//  Created by Carl Eriksson on 29/11/2020.
//

import Foundation
import UIKit

internal class PrimerView: UIView {

    //    @IBInspectable var cornerRadius: CGFloat {
    //        get {
    //            return layer.cornerRadius
    //        }
    //        set {
    //            layer.cornerRadius = newValue
    //        }
    //    }
    //
    //    @IBInspectable var borderWidth: CGFloat {
    //        get {
    //            return layer.borderWidth
    //        }
    //        set {
    //            layer.borderWidth = newValue
    //        }
    //    }
    //
    //    @IBInspectable var borderColor: UIColor? {
    //        get {
    //            if let cgColor = layer.borderColor {
    //                return UIColor(cgColor: cgColor)
    //            } else {
    //                return nil
    //            }
    //
    //        }
    //        set {
    //            layer.borderColor = newValue?.cgColor
    //        }
    //    }

    var shadowColor: UIColor? {
        get {
            if let cgColor = layer.shadowColor {
                return UIColor(cgColor: cgColor)
            } else {
                return nil
            }

        }
        set {
            layer.shadowColor = newValue?.cgColor
        }
    }

    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }

    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }

    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }

    func addShadow(opacity: Float = 0.5, radius: CGFloat = 3, offset: CGSize = CGSize(width: 0, height: 2)) {
        shadowColor = .black
        shadowRadius = radius
        shadowOpacity = opacity
        shadowOffset = offset
        layer.masksToBounds = false
    }

    func addBottomShadow() {
        let shadowLayer = CAShapeLayer()
        shadowLayer.masksToBounds = false
        shadowLayer.shadowRadius = 4
        shadowLayer.shadowOpacity = 0.4
        shadowLayer.shadowColor = UIColor.gray.cgColor
        shadowLayer.shadowOffset = CGSize(width: 1, height: 1)
        shadowLayer.shadowPath = UIBezierPath(rect: CGRect(x: 0,
                                                           y: bounds.maxY,
                                                           width: bounds.width,
                                                           height: shadowLayer.shadowRadius)).cgPath
        shadowLayer.cornerRadius = 8
        self.layer.addSublayer(shadowLayer)
    }

    func addBottomBorder(_ color: CGColor = UIColor.white.cgColor) {
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: self.frame.size.height + 9, width: self.bounds.width, height: 1)
        bottomLine.backgroundColor = color
        layer.addSublayer(bottomLine)
    }

    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }

    func pin(to superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
    }

    func removeSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }

}
