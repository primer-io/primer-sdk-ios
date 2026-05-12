//
//  PrimerCityFieldView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
@_spi(PrimerInternal) import PrimerFoundation

public final class PrimerCityFieldView: PrimerSimpleCardFormTextFieldView {

    var city: String? {
        textField.internalText
    }

    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "city_txt_fld"
        isEditingAnalyticsEnabled = true
        textField.delegate = self
        editingAnalyticsObjectId = .billingAddressCity
        validationError = .invalidCity(message: "City is not valid.")
        isValid = { text in
            text.isValidNonDecimalString
        }
    }
}
