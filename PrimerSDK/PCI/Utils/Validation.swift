import UIKit

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
    
    private func luhnCheck(_ number: String) -> Bool {
        var sum = 0
        let digitStrings = number.reversed().map { String($0) }
        
        for tuple in digitStrings.enumerated() {
            if let digit = Int(tuple.element) {
                let odd = tuple.offset % 2 == 1
                
                switch (odd, digit) {
                case (true, 9):
                    sum += 9
                case (true, 0...8):
                    sum += (digit * 2) % 9
                default:
                    sum += digit
                }
            } else {
                return false
            }
        }
        return sum % 10 == 0
    }
    
    func nameFieldIsNotValid(_ entry: String?) -> (Bool, String) {
        
        guard let entry = entry else { return (true, "Name required") }
        
        let name = entry.filter { !$0.isWhitespace }
        
        let nameIsEmpty = name.count < 1
        if (nameIsEmpty) { return (true, "Name field can't be empty") }
        
        return (false, "")
        
    }
    
    func cardFieldIsNotValid(_ entry: String?) -> (Bool, String) {
        
        guard let entry = entry else { return (true, "Card number required") }
        
        let number = entry.filter { !$0.isWhitespace }
        
        let containsNotOnlyNumbers = number.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil
        if (containsNotOnlyNumbers) { return (true, "Card number must contain only digits") }
        
        let containsTooFewDigits = number.count < 16
        if (containsTooFewDigits) { return (true, "Card number is too short") }
        
        let isNotALuhnNumber = !luhnCheck(number)
        if (isNotALuhnNumber)  { return (true, "Card number is not valid") }
        
        return (false, "")
    }
    
    private func expiryYearIsNotValid(_ year: String.SubSequence) -> (Bool, String) {
        
        guard var yearIntValue = Int(year) else { return (true, "Expiry year is required") }
        yearIntValue += 2000
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let yearAlreadyPassed = yearIntValue < currentYear
        if (yearAlreadyPassed) { return (true, "Expiry date already passed") }
        
        return (false, "")
    }
    
    private func expiryMonthIsNotValid(_ month: String.SubSequence, year: String.SubSequence) -> (Bool, String) {
        
        guard let monthIntValue = Int(month) else { return (true, "Expiry month is required") }
        
        let monthIntValueIsNotValid = monthIntValue < 1 || monthIntValue > 12
        if (monthIntValueIsNotValid) { return (true, "Expiry month input is not a valid month") }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        guard var yearIntValue = Int(year) else { return (true, "Expiry year is required") }
        yearIntValue += 2000
        let yearIsCurrentyYear = yearIntValue == currentYear
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let monthAlreadyPassed = monthIntValue < currentMonth && yearIsCurrentyYear
        if (monthAlreadyPassed) { return (true, "Expiry date already passed") }
        
        return (false, "")
    }
    
    func expiryFieldIsNotValid(_ entry: String?) -> (Bool, String) {
        
        guard let entry = entry else { return (true, "Expiry text field required") }
        
        let expiry = entry.filter { !$0.isWhitespace }
        let expiryValues = expiry.split(separator: "/")
        
        if (expiryValues.count != 2) { return (true, "Expiry text field is invalid") }
        
        let month = expiryValues[0]
        let year = expiryValues[1]
        
        let yearValidation = expiryYearIsNotValid(year)
        if (yearValidation.0) { return yearValidation }
        
        let monthValidation = expiryMonthIsNotValid(month, year: year)
        if (monthValidation.0) { return monthValidation }
        
        return (false, "")
    }
    
    func CVCFieldIsNotValid(_ entry: String?) -> (Bool, String) {
        
        guard let entry = entry else { return (true, "CVC is required") }
        
        let cvc = entry.filter { !$0.isWhitespace }
        
        let containsNotOnlyNumbers = cvc.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil
        if (containsNotOnlyNumbers) { return (true, "CVC value is invalid") }
        
        let containsTooFewDigits = cvc.count < 3
        if (containsTooFewDigits) { return (true, "CVC value is too short") }
        
        return (false, "")
        
    }
}
