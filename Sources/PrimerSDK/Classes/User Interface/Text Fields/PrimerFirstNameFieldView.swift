import UIKit

public final class PrimerFirstNameFieldView: PrimerSimpleCardFormTextFieldView {

    internal var firstName: String? {
        return textField._text
    }

    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "first_name_txt_fld"
        isEditingAnalyticsEnabled = true
        textField.delegate = self
        editingAnalyticsObjectId = .billingAddressFirstName
        validationError = .invalidFirstName(
            message: "First name is not valid.",
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString)
        isValid = { text in
            return text.isValidNonDecimalString
        }
    }

    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string.isValidNonDecimalString == true || string.isEmpty else { return false }
        return super.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
    }
}
