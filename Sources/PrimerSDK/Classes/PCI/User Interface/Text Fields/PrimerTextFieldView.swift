//
//  PrimerTextFieldView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/21.
//

#if canImport(UIKit)

import UIKit

/// The PrimerTextFieldViewDelegate protocol can be used to retrieve information about the text input.
/// PrimerCardNumberFieldView, PrimerExpiryDateFieldView, PrimerCVVFieldView & PrimerCardholderNameFieldView
/// all have a delegate of PrimerTextFieldViewDelegate type.
public protocol PrimerTextFieldViewDelegate {
    /// Will return true if valid, false if invalid, nil if it cannot be detected yet. It is applied on all PrimerTextFieldViews.
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?)
    /// Will return the card network (e.g. Visa) detected, unknown if the network cannot be detected. Only applies on PrimerCardNumberFieldView
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
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork?) {}
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error) {}
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
    public var keyboardType: UIKeyboardType = .default { didSet { textField.keyboardType = keyboardType }}
    public var isTextFieldAccessibilityElement: Bool = false { didSet { textField.isAccessibilityElement = isTextFieldAccessibilityElement }}
    public var textFieldaccessibilityIdentifier: String? { didSet { textField.accessibilityIdentifier = textFieldaccessibilityIdentifier }}
    
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
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
    
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
        
        if let isValid = self.isValid {
            validation = (isValid(primerTextField._text ?? "") ?? false)
                ? PrimerTextField.Validation.valid
            : PrimerTextField.Validation.invalid(PrimerError.invalidValue(key: "primerTextField.text", value: textField.text, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
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
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
}

class PrimerCustomFieldView: UIView {
    
    var fieldView: PrimerTextFieldView!
    override var tintColor: UIColor! {
        didSet {
            topPlaceholderLabel.textColor = tintColor
            bottomLine.backgroundColor = tintColor
        }
    }
    var placeholderText: String?
    var rightImage1: UIImage? {
        didSet {
            rightImageView1Container.isHidden = rightImage1 == nil
            rightImageView1.image = rightImage1
        }
    }
    var rightImage1TintColor: UIColor? {
        didSet {
            rightImageView1.tintColor = rightImage1TintColor
        }
    }
    var rightImage2: UIImage? {
        didSet {
            rightImageView2.isHidden = rightImage2 == nil
            rightImageView2.image = rightImage2
        }
    }
    var rightImage2TintColor: UIColor? {
        didSet {
            rightImageView2.tintColor = rightImage2TintColor
        }
    }
    var errorText: String? {
        didSet {
            errorLabel.text = errorText ?? ""
        }
    }
    
    private var verticalStackView: UIStackView = UIStackView()
    private let errorLabel = UILabel()
    private let topPlaceholderLabel = UILabel()
    private let rightImageView1Container = UIView()
    private let rightImageView1 = UIImageView()   // As in the one furthest right
    private let rightImageView2Container = UIView()
    private let rightImageView2 = UIImageView()
    private let bottomLine = UIView()
    private var theme: PrimerThemeProtocol = DependencyContainer.resolve()

    func setup() {
        addSubview(verticalStackView)
        verticalStackView.alignment = .fill
        verticalStackView.axis = .vertical

        topPlaceholderLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        topPlaceholderLabel.text = placeholderText
        topPlaceholderLabel.textColor = theme.text.system.color
        verticalStackView.addArrangedSubview(topPlaceholderLabel)
        
        rightImageView1.contentMode = .scaleAspectFit
        rightImageView2.contentMode = .scaleAspectFit

        let textFieldStackView = UIStackView()
        textFieldStackView.alignment = .fill
        textFieldStackView.axis = .horizontal
        textFieldStackView.addArrangedSubview(fieldView)
        textFieldStackView.addArrangedSubview(rightImageView2)
        textFieldStackView.spacing = 6
        
        textFieldStackView.addArrangedSubview(rightImageView2Container)
        rightImageView2Container.translatesAutoresizingMaskIntoConstraints = false
        rightImageView2Container.addSubview(rightImageView2)
        rightImageView2.translatesAutoresizingMaskIntoConstraints = false
        rightImageView2.topAnchor.constraint(equalTo: rightImageView2Container.topAnchor, constant: 6).isActive = true
        rightImageView2.bottomAnchor.constraint(equalTo: rightImageView2Container.bottomAnchor, constant: -6).isActive = true
        rightImageView2.leadingAnchor.constraint(equalTo: rightImageView2Container.leadingAnchor, constant: 0).isActive = true
        rightImageView2.trailingAnchor.constraint(equalTo: rightImageView2Container.trailingAnchor, constant: 0).isActive = true
        rightImageView2.widthAnchor.constraint(equalTo: rightImageView2Container.heightAnchor, multiplier: 1.0).isActive = true
        
        textFieldStackView.addArrangedSubview(rightImageView1Container)
        rightImageView1Container.translatesAutoresizingMaskIntoConstraints = false
        rightImageView1Container.addSubview(rightImageView1)
        rightImageView1.translatesAutoresizingMaskIntoConstraints = false
        rightImageView1.topAnchor.constraint(equalTo: rightImageView1Container.topAnchor, constant: 10).isActive = true
        rightImageView1.bottomAnchor.constraint(equalTo: rightImageView1Container.bottomAnchor, constant: -10).isActive = true
        rightImageView1.leadingAnchor.constraint(equalTo: rightImageView1Container.leadingAnchor, constant: 0).isActive = true
        rightImageView1.trailingAnchor.constraint(equalTo: rightImageView1Container.trailingAnchor, constant: 0).isActive = true
        rightImageView1.widthAnchor.constraint(equalTo: rightImageView1.heightAnchor, multiplier: 1.0).isActive = true
        
        bottomLine.backgroundColor = theme.colors.primary
        bottomLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        verticalStackView.addArrangedSubview(textFieldStackView)
        verticalStackView.addArrangedSubview(bottomLine)

        errorLabel.textColor = theme.text.error.color
        errorLabel.heightAnchor.constraint(equalToConstant: 12.0).isActive = true
        errorLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        errorLabel.text = nil
        
        verticalStackView.addArrangedSubview(errorLabel)

        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        verticalStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        verticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        verticalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}

#endif
