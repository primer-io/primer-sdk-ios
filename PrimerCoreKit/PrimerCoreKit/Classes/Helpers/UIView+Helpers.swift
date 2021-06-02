//
//  UIView+Helpers.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 24/5/21.
//

//import UIKit
//
//internal class PrimerView: UIView {
//
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
//
//    @IBInspectable var shadowColor: UIColor? {
//        get {
//            if let cgColor = layer.shadowColor {
//                return UIColor(cgColor: cgColor)
//            } else {
//                return nil
//            }
//
//        }
//        set {
//            layer.shadowColor = newValue?.cgColor
//        }
//    }
//
//    @IBInspectable var shadowRadius: CGFloat {
//        get {
//            return layer.shadowRadius
//        }
//        set {
//            layer.shadowRadius = newValue
//        }
//    }
//
//    @IBInspectable var shadowOffset: CGSize {
//        get {
//            return layer.shadowOffset
//        }
//        set {
//            layer.shadowOffset = newValue
//        }
//    }
//
//    @IBInspectable var shadowOpacity: Float {
//        get {
//            return layer.shadowOpacity
//        }
//        set {
//            layer.shadowOpacity = newValue
//        }
//    }
//
//}
