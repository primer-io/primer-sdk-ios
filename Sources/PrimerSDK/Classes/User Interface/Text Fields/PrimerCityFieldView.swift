import UIKit

public final class PrimerCityFieldView: PrimerSimpleCardFormTextFieldView {

    internal var city: String? {
        return textField._text
    }

    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "city_txt_fld"
        isEditingAnalyticsEnabled = true
        textField.delegate = self
        editingAnalyticsObjectId = .billingAddressCity
        validationError = .invalidState(
            message: "State is not valid.",
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString)
        isValid = { text in
            return text.isValidNonDecimalString
        }
    }
}
