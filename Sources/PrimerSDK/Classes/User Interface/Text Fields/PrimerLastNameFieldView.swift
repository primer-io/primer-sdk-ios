//
//  PrimerLastNameFieldView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerUI
import UIKit

extension PrimerTextFieldView {
    var editingAnalyticsObjectId: ObjectId? {
        get {
            _editingAnalyticsObjectId.flatMap(ObjectId.init)
        }
        set {
            _editingAnalyticsObjectId = newValue?.rawValue
        }
    }
}

public final class PrimerLastNameFieldView: PrimerSimpleCardFormTextFieldView {

    var lastName: String? {
        textField.internalText
    }

    override public func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "last_name_txt_fld"
        isEditingAnalyticsEnabled = true
        textField.delegate = self
        editingAnalyticsObjectId = .billingAddressLastName
        validationError = .invalidLastName(message: "Last name is not valid.")
        isValid = { text in
            text.isValidNonDecimalString
        }
    }

    override public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string.isValidNonDecimalString == true || string.isEmpty else { return false }
        return super.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
    }
}
