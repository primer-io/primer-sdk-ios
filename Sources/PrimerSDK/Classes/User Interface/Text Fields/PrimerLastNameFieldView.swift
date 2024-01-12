import UIKit

public final class PrimerLastNameFieldView: PrimerSimpleCardFormTextFieldView {

    internal var lastName: String? {
        return textField.internalText
    }

    override func xibSetup() {
        super.xibSetup()
        isTextFieldAccessibilityElement = true
        textFieldaccessibilityIdentifier = "last_name_txt_fld"
        isEditingAnalyticsEnabled = true
        textField.delegate = self
        editingAnalyticsObjectId = .billingAddressLastName
        validationError = .invalidLastName(
            message: "Last name is not valid.",
            userInfo: [
                "file": #file,
                "class": "\(Self.self)",
                "function": #function,
                "line": "\(#line)"
            ],
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
