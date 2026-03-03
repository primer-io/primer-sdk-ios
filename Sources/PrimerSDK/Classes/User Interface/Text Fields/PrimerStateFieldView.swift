//
//  PrimerStateFieldView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public final class PrimerStateFieldView: PrimerSimpleCardFormTextFieldView {

    var state: String? {
        textField.internalText
    }

    override public func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "state_txt_fld"
        isEditingAnalyticsEnabled = true
        textField.delegate = self
        editingAnalyticsObjectId = .billingAddressState
        validationError = .invalidState(message: "State is not valid.")
        isValid = { text in
            text.isValidNonDecimalString
        }
    }

    override public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string.isValidNonDecimalString == true || string.isEmpty else { return false }
        return super.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
    }
}
