#if canImport(UIKit)

import UIKit

public final class PrimerStateFieldView: PrimerSimpleCardFormTextFieldView {
    
    internal var state: String? {
        return textField._text
    }
    
    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "state_txt_fld"
        isEditingAnalyticsEnabled = true
        editingAnalyticsObjectId = .billingAddressState
        validationError = .invalidState(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
        isValid = { text in
            return text.isTypingNonDecimalCharacters
        }
    }
}

#endif
