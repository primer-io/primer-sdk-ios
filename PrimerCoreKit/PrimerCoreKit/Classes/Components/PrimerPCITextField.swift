//
//  PrimerPCITextField.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 11/5/21.
//

import UIKit

@IBDesignable
public class PrimerPCITextField: PrimerNibView {
    
    // MARK: - PROPERTIES & OUTLETS
    
    // MARK: Colors
    
    private var _borderColor: UIColor?
    @IBInspectable
    public var borderColor: UIColor? {
        get {
            return _borderColor
        }
        set {
            _borderColor = newValue
            primerTextField.tintColor = newValue
            textFieldContainerView.layer.borderColor = newValue?.cgColor
        }
    }
    
    private var _checkmarkColor: UIColor?
    @IBInspectable
    public var checkmarkColor: UIColor? {
        get {
            return _checkmarkColor
        }
        set {
            _checkmarkColor = newValue
        }
    }
    
    private var _errorColor: UIColor?
    @IBInspectable
    public var errorColor: UIColor? {
        get {
            return _errorColor
        }
        set {
            _errorColor = newValue
        }
    }
    
    @IBInspectable
    public var placeholderTextColor: UIColor? {
        didSet {
            placeholderLabel.textColor = placeholderTextColor
        }
    }
    
    @IBInspectable
    public var textColor: UIColor? {
        didSet {
            primerTextField.textColor = textColor
        }
    }
    
    // MARK: Borders and corners
    
    private let bottomLine = CALayer()
    @IBInspectable
    public var hasOnlyBottomBorder: Bool = false {
        didSet {
            if hasOnlyBottomBorder {
                textFieldContainerView.layer.borderWidth = 0
                textFieldContainerView.layer.borderColor = nil
                
                bottomLine.frame = CGRect(x: 0, y: self.frame.size.height - _borderWidth, width: self.bounds.width, height: _borderWidth)
                bottomLine.backgroundColor = _borderColor?.cgColor
                layer.addSublayer(bottomLine)
                
            } else {
                bottomLine.removeFromSuperlayer()
                borderWidth = _borderWidth
                borderColor = _borderColor
            }
        }
    }
    
    @IBInspectable
    public var cornerRadius: CGFloat {
        get {
            return textFieldContainerView.layer.cornerRadius
        }
        set {
            textFieldContainerView.layer.cornerRadius = newValue
        }
    }
    
    private var _borderWidth: CGFloat!
    @IBInspectable
    public var borderWidth: CGFloat {
        get {
            return _borderWidth
        }
        set {
            _borderWidth = newValue
            textFieldContainerView.layer.borderWidth = newValue
        }
    }
    
    // MARK: Images
    
    public var validationSuccessIcon: UIImage? = UIImage(named: "check", in: Bundle.primerCoreKitResources, compatibleWith: nil)
    public var validationFailureIcon: UIImage? = UIImage(named: "x", in: Bundle.primerCoreKitResources, compatibleWith: nil)
    
    // MARK: Values
    
    @IBInspectable
    public var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            placeholderContainerView.isHidden = (placeholder ?? "").isEmpty
        }
    }
    
    // MARK: Validation properties

    public enum TextFieldValidation {
        case valid, error(_ error: Error?), empty
    }
    
    public var isValid: ((_ text: String) -> Bool)?
    
    public var validation: TextFieldValidation = .empty {
        didSet {
            switch validation {
            case .valid:
                validationImageView.image = validationSuccessIcon?.withRenderingMode(.alwaysTemplate)
                validationImageView.tintColor = checkmarkColor
                validationContainerView.isHidden = false
                
            case .error:
                validationImageView.image = validationFailureIcon?.withRenderingMode(.alwaysTemplate)
                validationImageView.tintColor = errorColor
                validationContainerView.isHidden = false
                
            case .empty:
                validationImageView.image = nil
                validationContainerView.isHidden = true
            }
        }
    }
 
    // MARK: Outlets
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var textFieldContainerView: UIView!
    @IBOutlet private weak var textFieldStackView: UIStackView!
    @IBOutlet internal weak var primerTextField: PrimerTextField!
    @IBOutlet weak var cardIconContainerView: UIView!
    @IBOutlet internal weak var cardIconView: UIImageView!
    @IBOutlet weak var validationContainerView: UIView!
    @IBOutlet private weak var validationImageView: UIImageView!
    @IBOutlet weak var placeholderContainerView: UIView!
    @IBOutlet private weak var placeholderLabel: UILabel!

    // MARK: - SETUP
    
    override func xibSetup() {
        super.xibSetup()
        primerTextField.delegate = self
        placeholderContainerView.isHidden = (placeholder ?? "").isEmpty
        cardIconContainerView.isHidden = true
    }
    
}

// MARK: - TEXT FIELD DELEGATE

extension PrimerPCITextField: UITextFieldDelegate {
    public func textFieldDidEndEditing(_ textField: UITextField) {
        guard let primerTextField = textField as? PrimerTextField else { return }
        let err = NSError(domain: "primer.core.kit", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid value."])
        validation = (self.isValid?(primerTextField._text ?? "") ?? false) ? .valid : .error(err)
    }
}

















internal class PrimerTextField: UITextField {
    
    override var delegate: UITextFieldDelegate? {
        get {
            return super.delegate
        }
        set {
            if let primerPCITextField = newValue as? PrimerPCITextField {
                super.delegate = primerPCITextField
            } else {
                // Do nothing, let the delegate to whatever it previosuly was.
            }
        }
    }
    
    internal var _text: String?
    
    override var text: String? {
        get {
            return "****"
        }
        set {
            super.text = newValue
            _text = super.text
        }
    }
        
}
