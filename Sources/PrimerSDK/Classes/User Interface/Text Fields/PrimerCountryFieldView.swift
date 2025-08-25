//
//  PrimerCountryFieldView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

public final class PrimerCountryFieldView: PrimerSimpleCardFormTextFieldView {

    internal var country: String? {
        return textField.internalText
    }

    internal var countryCode: CountryCode?

    internal var onOpenCountriesListPressed: PrimerAction?

    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "country_txt_fld"
        isEditingAnalyticsEnabled = true
        textField.delegate = self
        editingAnalyticsObjectId = .billingAddressCountry
        validationError = .invalidCountry(message: "Country is not valid.")
        isValid = { text in
            return !text.isEmpty
        }
        setupTextFieldView()
    }

    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
}

extension PrimerCountryFieldView {

    // MARK: - Setup

    private func setupTextFieldView() {
        let rightViewTap = UITapGestureRecognizer()
        rightViewTap.addTarget(self, action: #selector(onRightViewPressed))
        textField.addGestureRecognizer(rightViewTap)
    }
}

extension PrimerCountryFieldView {

    // MARK: - Action

    @objc
    private func onRightViewPressed() {
        onOpenCountriesListPressed?()
    }

}
