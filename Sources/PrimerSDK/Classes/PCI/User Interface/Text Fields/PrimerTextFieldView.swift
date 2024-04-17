//
//  PrimerTextFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/21.
//

// swiftlint:disable function_body_length
import UIKit

/// The PrimerTextFieldViewDelegate protocol can be used to retrieve information about the text input.
/// PrimerCardNumberFieldView, PrimerExpiryDateFieldView, PrimerCVVFieldView & PrimerCardholderNameFieldView
/// all have a delegate of PrimerTextFieldViewDelegate type.
public protocol PrimerTextFieldViewDelegate: AnyObject {
    /// Will return true if valid, false if invalid, nil if it cannot be detected yet.
    /// It is applied on all PrimerTextFieldViews.
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?)
    /// Will return the card network (e.g. Visa) detected, unknown if the network cannot be detected.
    /// Only applies on PrimerCardNumberFieldView
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork?)
    /// Will return a the validation error on the text input.
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error)

    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView)

    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool

    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool

    func primerTextFieldViewDidEndEditing(_ primerTextFieldView: PrimerTextFieldView)
}

public extension PrimerTextFieldViewDelegate {
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {}
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView,
                             didDetectCardNetwork cardNetwork: CardNetwork?) {}
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView,
                             validationDidFailWithError error: Error) {}
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {}
    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool { return true }
    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool { return true}
    func primerTextFieldViewDidEndEditing(_ primerTextFieldView: PrimerTextFieldView) {}
}

public class PrimerTextFieldView: PrimerNibView, UITextFieldDelegate {

    @IBOutlet internal weak var textField: PrimerTextField!
    internal var isValid: ((_ text: String) -> Bool?)?
    internal(set) public var isTextValid: Bool = false
    internal var editingAnalyticsObjectId: Analytics.Event.Property.ObjectId?
    internal(set) public var isEditingAnalyticsEnabled: Bool = false
    public var delegate: PrimerTextFieldViewDelegate?
    internal var validation: PrimerTextField.Validation = .notAvailable {
        didSet {
            if isValid == nil {
                isTextValid = true
            } else {
                switch validation {
                case .valid:
                    isTextValid = true
                default:
                    isTextValid = false
                }
            }
        }
    }
    public var isEmpty: Bool {
        return textField.isEmpty
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
    public var borderStyle: UITextField.BorderStyle = .none {
        didSet { textField.borderStyle = borderStyle }
    }
    public var defaultTextAttributes: [NSAttributedString.Key: Any] = [:] {
        didSet { textField.defaultTextAttributes = defaultTextAttributes }
    }
    public var placeholder: String? {
        didSet { textField.placeholder = placeholder }
    }
    public var attributedPlaceholder: NSAttributedString? { didSet {
        textField.attributedPlaceholder = attributedPlaceholder }
    }
    public var clearsOnBeginEditing: Bool = false {
        didSet { textField.clearsOnBeginEditing = clearsOnBeginEditing }
    }
    public var adjustsFontSizeToFitWidth: Bool = false {
        didSet { textField.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth }
    }
    public var minimumFontSize: CGFloat = 0.0 { didSet { textField.minimumFontSize = minimumFontSize } }
    public var background: UIImage? { didSet { textField.background = background } }
    public var disabledBackground: UIImage? { didSet { textField.disabledBackground = disabledBackground } }
    public var isEditing: Bool {
        return textField.isEditing
    }
    public var allowsEditingTextAttributes: Bool = false {
        didSet { textField.allowsEditingTextAttributes = allowsEditingTextAttributes }
    }
    public var typingAttributes: [NSAttributedString.Key: Any]? {
        didSet { textField.typingAttributes = typingAttributes }
    }
    public var clearButtonMode: UITextField.ViewMode = .never { didSet { textField.clearButtonMode = clearButtonMode }}
    public var leftViewMode: UITextField.ViewMode = .never { didSet { textField.leftViewMode = leftViewMode }}
    public var rightViewMode: UITextField.ViewMode = .never { didSet { textField.rightViewMode = rightViewMode }}
    public var keyboardType: UIKeyboardType = .default {
        didSet { textField.keyboardType = keyboardType }
    }
    public var isTextFieldAccessibilityElement: Bool = false {
        didSet { textField.isAccessibilityElement = isTextFieldAccessibilityElement }
    }
    public var textFieldaccessibilityIdentifier: String? {
        didSet { textField.accessibilityIdentifier = textFieldaccessibilityIdentifier }
    }

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

    public var clearsOnInsertion: Bool = false { didSet { textField.clearsOnInsertion = clearsOnInsertion }}

    override func loadNib() -> UIView {
        let bundle = Bundle.primerResources
        let nib = UINib(nibName: PrimerTextFieldView.className, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView
        else {
            fatalError()
        }
        return view
    }

    override func xibSetup() {
        super.xibSetup()
        backgroundColor = .clear
        view?.backgroundColor = .clear
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

        if let isValid = self.isValid {
            validation = (isValid(primerTextField.internalText ?? "") ?? false)
                ? PrimerTextField.Validation.valid
                : PrimerTextField.Validation.invalid(PrimerError.invalidValue(key: "primerTextField.text",
                                                                              value: textField.text,
                                                                              userInfo: .errorUserInfoDictionary(),
                                                                              diagnosticsId: UUID().uuidString))
        }

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

        delegate?.primerTextFieldViewDidEndEditing(self)
    }

    public func textField(_ textField: UITextField,
                          shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
        return true
    }

}

internal class PaddedImageView: PrimerImageView {

    internal private(set) var insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    override var alignmentRectInsets: UIEdgeInsets {
        return insets
    }

    convenience init(insets: UIEdgeInsets) {
        self.init(image: nil)
    }

    convenience init(image: UIImage?, insets: UIEdgeInsets) {
        self.init(image: image)
        self.insets = insets
    }

    override init(image: UIImage?) {
        super.init(image: image)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
// swiftlint:enable function_body_length
