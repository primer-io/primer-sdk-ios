#if canImport(UIKit)

import UIKit

public class PrimerAddressLineFieldView: PrimerSimpleCardFormTextFieldView {
    
    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        isEditingAnalyticsEnabled = true
        textField.delegate = self
        isValid = { text in
            return !text.isEmpty
        }
        validationError = .invalidAddress(
            userInfo: [
                "file": #file,
                "class": "\(Self.self)",
                "function": #function,
                "line": "\(#line)"
            ],
            diagnosticsId: UUID().uuidString)
    }
}

public final class PrimerAddressLine1FieldView: PrimerAddressLineFieldView {
    
    internal var addressLine1: String? {
        return textField._text
    }
    
    override func xibSetup() {
        super.xibSetup()
        textFieldaccessibilityIdentifier = "address_line_1_txt_fld"
        editingAnalyticsObjectId = .billingAddressLine1
    }
}

public final class PrimerAddressLine2FieldView: PrimerSimpleCardFormTextFieldView {
    
    internal var addressLine2: String? {
        return textField._text
    }
    
    override func xibSetup() {
        super.xibSetup()
        textFieldaccessibilityIdentifier = "address_line_2_txt_fld"
        editingAnalyticsObjectId = .billingAddressLine2
        validation = .notAvailable
    }
}

#endif
