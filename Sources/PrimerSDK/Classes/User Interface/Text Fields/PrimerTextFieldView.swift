//
//  PrimerTextFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/21.
//

import UIKit

/// The PrimerTextFieldViewDelegate protocol can be used to retrieve information about the text input.
/// PrimerCardNumberFieldView, PrimerExpiryDateFieldView, PrimerCVVFieldView & PrimerCardholderNameFieldView
/// all have a delegate of PrimerTextFieldViewDelegate type.
public protocol PrimerTextFieldViewDelegate {
    /// Will return true if valid, false if invalid, nil if it cannot be detected yet. It is applied on all PrimerTextFieldViews.
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?)
    /// Will return the card network (e.g. Visa) detected, unknown if the network cannot be detected. Only applies on PrimerCardNumberFieldView
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork)
    /// Will return a the validation error on the text input.
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error)
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView)
    
    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool
    
    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool
}

public extension PrimerTextFieldViewDelegate {
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {}
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork) {}
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error) {}
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {}
    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool { return true }
    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool { return true}
}

public class PrimerTextFieldView: PrimerNibView, UITextFieldDelegate {
    
    @IBOutlet internal weak var textField: PrimerTextField!
    internal var isValid: ((_ text: String) -> Bool?)?
    internal(set) public var isTextValid: Bool = false
    public var delegate: PrimerTextFieldViewDelegate?
    internal var validation: PrimerTextField.Validation = .notAvailable {
        didSet {
            switch validation {
            case .valid:
                isTextValid = true
            default:
                isTextValid = false
            }
        }
    }
    
    // MARK: - PROXY
    
    public override var backgroundColor: UIColor? { didSet {
        textField?.backgroundColor = backgroundColor
    } }
    public var text: String? { didSet { textField.text = text } }
    public var attributedText: NSAttributedString? { didSet { textField.attributedText = attributedText } }
    public var textColor: UIColor? { didSet { textField.textColor = textColor } }
    public var font: UIFont? { didSet { textField.font = font } }
    public var textAlignment: NSTextAlignment = .left { didSet { textField.textAlignment = textAlignment } }
    public var borderStyle: UITextField.BorderStyle = .none { didSet { textField.borderStyle = borderStyle } }
    public var defaultTextAttributes: [NSAttributedString.Key: Any] = [:] { didSet { textField.defaultTextAttributes = defaultTextAttributes } }
    public var placeholder: String? { didSet { textField.placeholder = placeholder } }
    public var attributedPlaceholder: NSAttributedString? { didSet { textField.attributedPlaceholder = attributedPlaceholder } }
    public var clearsOnBeginEditing: Bool = false { didSet { textField.clearsOnBeginEditing = clearsOnBeginEditing } }
    public var adjustsFontSizeToFitWidth: Bool = false { didSet { textField.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth } }
    public var minimumFontSize: CGFloat = 0.0 { didSet { textField.minimumFontSize = minimumFontSize } }
    public var background: UIImage? { didSet { textField.background = background } }
    public var disabledBackground: UIImage? { didSet { textField.disabledBackground = disabledBackground } }
    public var isEditing: Bool {
        return textField.isEditing
    }
    public var allowsEditingTextAttributes: Bool = false { didSet { textField.allowsEditingTextAttributes = allowsEditingTextAttributes }}
    public var typingAttributes: [NSAttributedString.Key: Any]? { didSet { textField.typingAttributes = typingAttributes }}
    public var clearButtonMode: UITextField.ViewMode = .never { didSet { textField.clearButtonMode = clearButtonMode }}
    public var leftViewMode: UITextField.ViewMode = .never { didSet { textField.leftViewMode = leftViewMode }}
    public var rightViewMode: UITextField.ViewMode = .never { didSet { textField.rightViewMode = rightViewMode }}
    
    public func borderRectForBounds(forBounds bounds: CGRect) -> CGRect {
        return textField.borderRect(forBounds: bounds)
    }
    
    public func textRect(forBounds bounds: CGRect) -> CGRect {
        return textField.textRect(forBounds: bounds)
    }
    
    public func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return textField.placeholderRect(forBounds: bounds)
    }
    
    public func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textField.editingRect(forBounds: bounds)
    }
    
    public func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        return textField.clearButtonRect(forBounds: bounds)
    }
    
    public func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return textField.leftViewRect(forBounds: bounds)
    }
    
    public func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return textField.rightViewRect(forBounds: bounds)
    }
    
    public func drawText(in rect: CGRect) {
        return textField.drawText(in: rect)
    }
    
    public func drawPlaceholderInRect(in rect: CGRect) {
        return textField.drawPlaceholder(in: rect)
    }
    
    public override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    public override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
//    public override var inputView: UIView? {
//        get {
//            return textField.inputView
//        }
//        set {
//            textField.inputView = newValue
//        }
//    }
//    public override var inputAccessoryView: UIView? {
//        get {
//            return textField.inputAccessoryView
//        }
//        set {
//            textField.inputAccessoryView = newValue
//        }
//    }
    public var clearsOnInsertion: Bool = false { didSet { textField.clearsOnInsertion = clearsOnInsertion }}
    
    
    override func xibSetup() {
        super.xibSetup()
                        
        backgroundColor = .clear
        view.backgroundColor = .clear
        textField.backgroundColor = backgroundColor
        textField.delegate = self
    }
    
    // MARK: - TEXT FIELD DELEGATE
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.primerTextFieldViewDidBeginEditing(self)
    }
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return delegate?.primerTextFieldViewShouldBeginEditing(self) ?? true
    }
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return delegate?.primerTextFieldViewShouldEndEditing(self) ?? true
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        guard let primerTextField = textField as? PrimerTextField else { return }
        validation = (self.isValid?(primerTextField._text ?? "") ?? false)
            ? PrimerTextField.Validation.valid
            : PrimerTextField.Validation.invalid(PrimerError.invalidValue(key: "primerTextField.text"))
        
        switch validation {
        case .valid:
            delegate?.primerTextFieldView(self, isValid: true)

        case .invalid(let err):
            delegate?.primerTextFieldView(self, isValid: false)
            
            if let err = err {
                delegate?.primerTextFieldView(self, validationDidFailWithError: err)
            }
    
        case .notAvailable:
            delegate?.primerTextFieldView(self, isValid: nil)
        }
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let primerTextField = textField as? PrimerTextField else { return true }
        return true
    }
    
}

