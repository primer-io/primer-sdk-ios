//
//  PrimerCardholderNameFieldView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public final class PrimerCardholderNameFieldView: PrimerSimpleCardFormTextFieldView {

    var cardholderName: String {
        textField.internalText ?? ""
    }

    override public func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "card_holder_txt_fld"
        isEditingAnalyticsEnabled = true
        textField.delegate = self
        editingAnalyticsObjectId = .cardHolder
        validationError = .invalidCardholderName(message: "Cardholder name is not valid.")
        isValid = { text in
            text.isValidNonDecimalString && 2 <= text.count && text.count < 45
        }
    }

    override public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string.isValidNonDecimalString == true || string.isEmpty else { return false }
        return super.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
    }
}
