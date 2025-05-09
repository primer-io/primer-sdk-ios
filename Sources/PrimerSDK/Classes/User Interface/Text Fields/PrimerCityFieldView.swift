import UIKit

public final class PrimerCityFieldView: PrimerSimpleCardFormTextFieldView {

    var city: String? {
        return textField.internalText
    }

    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "city_txt_fld"
        isEditingAnalyticsEnabled = true
        textField.delegate = self
        editingAnalyticsObjectId = .billingAddressCity
        validationError = .invalidCity(
            message: "City is not valid.",
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString)
        isValid = { text in
            text.isValidNonDecimalString
        }
    }
}
