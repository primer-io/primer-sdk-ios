import Foundation
class Validation {
    public func validateName(name: String) ->Bool {
        // Length be 18 characters max and 3 characters minimum, you can always modify.
        let nameRegex = "^\\w{2,18}$"
        let trimmedString = name.trimmingCharacters(in: .whitespaces)
        let validateName = NSPredicate(format: "SELF MATCHES %@", nameRegex)
        let isValidateName = validateName.evaluate(with: trimmedString)
        return isValidateName
    }
    
    public func validaCardNumber(cardNumber: String) -> Bool {
        let trimmedString = cardNumber.trimmingCharacters(in: .whitespaces)
        let isValidCard = trimmedString.count > 13
        return isValidCard
    }
    
    public func validateIsNotEmpty(entry: String) -> Bool {
        let trimmedString = entry.trimmingCharacters(in: .whitespaces)
        let isValid = trimmedString.count > 0
        return isValid
    }
}
