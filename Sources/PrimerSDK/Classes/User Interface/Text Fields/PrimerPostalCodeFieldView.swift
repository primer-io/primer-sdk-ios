#if canImport(UIKit)

import UIKit

public final class PrimerPostalCodeFieldView: PrimerTextFieldView {
    
    internal var postalCode: String {
        return textField._text ?? ""
    }
    
    override func xibSetup() {
        super.xibSetup()
        
        textField.keyboardType = .namePhonePad
        textField.isAccessibilityElement = true
        textField.accessibilityIdentifier = "postal_code_txt_fld"
        textField.delegate = self
        isValid = { text in
            // todo: look into more sophisticated postal code validation, ascii check for now
            return text.isValidPostalCode
        }
    }
    
    // todo: refactor into separate functions somewhere
    public override func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let positionOriginal = textField.beginningOfDocument
        let cursorLocation = textField.position(
            from: positionOriginal,
            offset: (range.location + NSString(string: string).length)
        )
        
        guard let primerTextField = textField as? PrimerTextField else { return true }
        let currentText = primerTextField._text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
                
        switch self.isValid?(newText) {
        case true:
            validation = .valid
        case false:
            let err = PrimerValidationError.invalidPostalCode(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            validation = .invalid(err)
        default:
            validation = .notAvailable
        }
                
        primerTextField._text = newText
        primerTextField.text = newText
        
        if let cursorLoc = cursorLocation {
            textField.selectedTextRange = textField.textRange(from: cursorLoc, to: cursorLoc)
        }
        
        switch validation {
        case .valid:
            delegate?.primerTextFieldView(self, isValid: true)
        default:
            delegate?.primerTextFieldView(self, isValid: nil)
        }
        
        return false
    }
    
}

#endif
