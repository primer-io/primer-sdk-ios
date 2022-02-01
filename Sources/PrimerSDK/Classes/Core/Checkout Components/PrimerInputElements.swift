//
//  PrimerInputElements.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

#if canImport(UIKit)

import UIKit

extension PrimerCheckoutComponents {
    
    @IBDesignable
    public class TextField: UITextField, PrimerInputElement {
        public var inputElementDelegate: PrimerInputElementDelegate! {
            didSet {
                self.checkoutModulesTextFieldDelegate = PrimerCheckoutComponents.Delegate(inputElement: self, inputElementDelegate: inputElementDelegate)
                self.delegate = self.checkoutModulesTextFieldDelegate
            }
        }
        public var type: PrimerInputElementType = .unknown
        public var detectedValueType: Any?
        public var isValid: Bool {
            return self.type.validate(value: self._text as Any, detectedValueType: self.detectedValueType)
        }
        public override var delegate: UITextFieldDelegate? {
            get {
                return nil
            }
            set {
                if newValue is PrimerCheckoutComponents.Delegate {
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
        
        private var checkoutModulesTextFieldDelegate: PrimerCheckoutComponents.Delegate?
        internal var _text: String?
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        public init(type: PrimerInputElementType, frame: CGRect) {
            self.type = type
            super.init(frame: frame)
        }
    }
}

#endif
