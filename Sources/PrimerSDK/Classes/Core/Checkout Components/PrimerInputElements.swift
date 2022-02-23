//
//  PrimerInputElements.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

#if canImport(UIKit)

import UIKit

public class PrimerInputElementDelegateContainer {
    var inputElement: PrimerInputElement
    var inputElementDelegate: PrimerInputElementDelegate
    
    init(inputElement: PrimerInputElement, inputElementDelegate: PrimerInputElementDelegate) {
        self.inputElement = inputElement
        self.inputElementDelegate = inputElementDelegate
    }
}

@IBDesignable
public class PrimerInputTextField: UITextField, PrimerInputElement {
    public weak var inputElementDelegate: PrimerInputElementDelegate! {
        didSet {
            self.checkoutModulesTextFieldDelegate = PrimerHeadlessUniversalCheckout.Delegate(inputElement: self, inputElementDelegate: inputElementDelegate)
            self.delegate = self.checkoutModulesTextFieldDelegate
        }
    }
    public var type: PrimerInputElementType = .cardNumber
    public var detectedValueType: Any?
    public var isValid: Bool {
        return self.type.validate(value: self._text as Any, detectedValueType: self.detectedValueType)
    }
    public override var delegate: UITextFieldDelegate? {
        get {
            return nil
        }
        set {
            if newValue is PrimerHeadlessUniversalCheckout.Delegate {
                super.delegate = newValue
            }
        }
    }
    public override var text: String? {
        get {
            return "****"
        }
        set {
            super.text = newValue
            self._text = newValue
        }
    }
    
    private var checkoutModulesTextFieldDelegate: PrimerHeadlessUniversalCheckout.Delegate?
    internal var _text: String?
    private lazy var _keyboardType: UIKeyboardType = {
        return self.type.keyboardType
    }()
    public override var keyboardType: UIKeyboardType {
        get { return _keyboardType }
        set { self._keyboardType = newValue }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public init(type: PrimerInputElementType, frame: CGRect) {
        self.type = type
        super.init(frame: frame)
    }
}

#endif
