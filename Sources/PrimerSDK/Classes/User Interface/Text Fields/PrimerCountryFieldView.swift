#if canImport(UIKit)

import UIKit

public final class PrimerCountryFieldView: PrimerSimpleCardFormTextFieldView {
    
    internal var country: String {
        return textField._text ?? ""
    }
    
    internal var countryCode: CountryCode?
    
    internal var onOpenCountriesListPressed: PrimerAction?
    
    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "country_txt_fld"
        isEditingAnalyticsEnabled = true
        editingAnalyticsObjectId = .billingAddressCountry
        validationError = .invalidCountry(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
        isValid = { text in
            return text.isTypingNonDecimalCharacters
        }
        setupTextFieldView()
    }
}

extension PrimerCountryFieldView {
    
    //MARK: - Setup
    
    private func setupTextFieldView() {
        let rightViewTap = UITapGestureRecognizer()
        rightViewTap.addTarget(self, action: #selector(onRightViewPressed))
        textField.addGestureRecognizer(rightViewTap)
    }
}

extension PrimerCountryFieldView {
    
    //MARK: - Action
    
    @objc
    private func onRightViewPressed() {
        onOpenCountriesListPressed?()
    }
    
}

#endif
