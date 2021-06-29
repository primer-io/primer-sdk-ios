//
//  PrimerTextFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/21.
//

import UIKit

public protocol PrimerTextFieldViewDelegate {
    func isTextValid(_ isValid: Bool?)
}

public extension PrimerTextFieldViewDelegate {
    func isTextValid(_ isValid: Bool?) {}
}

public class PrimerTextFieldView: PrimerNibView, UITextFieldDelegate {
    
    @IBOutlet internal weak var textField: PrimerTextField!
    
    // MARK: - PROXY
    
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
    
}

