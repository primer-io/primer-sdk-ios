//
//  PrimerSearchTextField.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 26/10/21.
//

#if canImport(UIKit)

import UIKit

internal class PrimerSearchTextField: UITextField, UITextFieldDelegate {
    
    struct Padding {
        static let horizontal: CGFloat = 6
        static let vertical: CGFloat = 3
    }
    let spacing: CGFloat = 6
    
    private var _delegate: UITextFieldDelegate?
    override var delegate: UITextFieldDelegate? {
        get {
            return _delegate
        }
        set {
            _delegate = newValue
        }
    }
    private let searchImage = UIImage(named: "search-icon", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    private let clearImage = UIImage(named: "error", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    private var rightImageView = UIImageView()
    
    override var placeholder: String? {
        didSet {
            if placeholder == nil {
                super.placeholder = placeholder
            } else {
                let theme: PrimerThemeProtocol = DependencyContainer.resolve()
                
                attributedPlaceholder = NSAttributedString(
                    string: placeholder!,
                    attributes: [NSAttributedString.Key.foregroundColor: theme.text.subtitle.color]
                )
            }
            
        }
    }
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        super.delegate = self
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        backgroundColor = theme.input.color
        
        rightImageView.image = searchImage
        rightImageView.contentMode = .scaleAspectFit
        textColor = theme.text.body.color
        
        rightImageView.tintColor = theme.paymentMethodButton.iconColor
        rightView = rightImageView
        
        let rightViewTap = UITapGestureRecognizer()
        rightViewTap.addTarget(self, action: #selector(clear))
        rightView?.isUserInteractionEnabled = true
        rightView?.addGestureRecognizer(rightViewTap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let tmpRect = rightViewRect(forBounds: bounds)
        return CGRect(
            x: Padding.horizontal,
            y: bounds.origin.y + Padding.vertical,
            width: bounds.size.width - spacing - tmpRect.size.width - 2*Padding.horizontal,
            height: bounds.size.height - Padding.vertical * 2
        )
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return self.textRect(forBounds: bounds)
    }
        
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let rightViewSize = CGSize(width: bounds.size.height/2, height: bounds.size.height/2) // CGSize(width: bounds.size.height - 2*Padding.vertical, height: bounds.size.height - 2*Padding.vertical)
        return CGRect(
            x: bounds.origin.x + bounds.size.width - Padding.horizontal - rightViewSize.width - spacing,
            y: bounds.origin.y + (bounds.size.height - rightViewSize.height)/2,
            width: rightViewSize.width,
            height: rightViewSize.height
        )
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var query: String
        
        if string.isEmpty {
            query = String((textField.text ?? "").dropLast())
        } else {
            query = (textField.text ?? "") + string
        }
        
        rightImageView.image = query.isEmpty ? searchImage : clearImage
        
        return (_delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string)) ?? true
    }
    
    @objc
    func clear() {
        self.text = nil
        rightImageView.image = searchImage
        _ = _delegate?.textFieldShouldClear?(self)
    }
}

#endif
