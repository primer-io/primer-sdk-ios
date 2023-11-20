//
//  PrimerInputElements.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

import UIKit

public class PrimerInputElementDelegateContainer {

    var element: PrimerHeadlessUniversalCheckoutInputElement
    var delegate: PrimerInputElementDelegate

    init(element: PrimerHeadlessUniversalCheckoutInputElement, delegate: PrimerInputElementDelegate) {
        self.element = element
        self.delegate = delegate
    }
}

public class PrimerInputTextField: UITextField, PrimerHeadlessUniversalCheckoutInputElement {
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

@IBDesignable
public class PrimerCardNumberInputElement: PrimerInputTextField {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.type = .cardNumber
    }

    override public init(type: PrimerInputElementType, frame: CGRect) {
        super.init(type: .cardNumber, frame: frame)
    }
}

@IBDesignable
public class PrimerExpiryDateInputElement: PrimerInputTextField {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.type = .expiryDate
    }

    override public init(type: PrimerInputElementType, frame: CGRect) {
        super.init(type: .expiryDate, frame: frame)
    }
}

@IBDesignable
public class PrimerCVVInputElement: PrimerInputTextField {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.type = .cvv
    }

    override public init(type: PrimerInputElementType, frame: CGRect) {
        super.init(type: .cvv, frame: frame)
    }
}

@IBDesignable
public class PrimerCardholderNameInputElement: PrimerInputTextField {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.type = .cardholderName
    }

    override public init(type: PrimerInputElementType, frame: CGRect) {
        super.init(type: .cardholderName, frame: frame)
    }
}

@IBDesignable
public class PrimerPostalCodeInputElement: PrimerInputTextField {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.type = .postalCode
    }

    override public init(type: PrimerInputElementType, frame: CGRect) {
        super.init(type: .postalCode, frame: frame)
    }
}
