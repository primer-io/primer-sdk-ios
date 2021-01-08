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
    
    func nameFieldIsNotValid(_ entry: String?) -> Bool {
        
        guard let entry = entry else { return true }
        
        let name = entry.filter { !$0.isWhitespace }
        
        let nameIsEmpty = name.count < 1
        if (nameIsEmpty) { return true }
        
        return false
        
    }
    
    func cardFieldIsNotValid(_ entry: String?) -> Bool {
        
        guard let entry = entry else { return true }
        
        let number = entry.filter { !$0.isWhitespace }
        
        let containsNotOnlyNumbers = number.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil
        if (containsNotOnlyNumbers) { return true }
        
        let containsTooFewDigits = number.count < 12
        if (containsTooFewDigits) { return true }
        
        let isNotALuhnNumber = !luhnCheck(number)
        if (isNotALuhnNumber)  { return true }
        
        return false
    }
    
    private func expiryYearIsNotValid(_ year: String.SubSequence) -> Bool {
        
        guard var yearIntValue = Int(year) else { return true }
        yearIntValue += 2000
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let yearAlreadyPassed = yearIntValue < currentYear
        if (yearAlreadyPassed) { return true }
        
        return false
        
    }
    
    private func expiryMonthIsNotValid(_ month: String.SubSequence) -> Bool {
        
        guard let monthIntValue = Int(month) else { return true }
        
        let monthIntValueIsNotValid = monthIntValue < 1 || monthIntValue > 12
        if (monthIntValueIsNotValid) { return true }
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let monthAlreadyPassed = monthIntValue < currentMonth
        if (monthAlreadyPassed) { return true }
        
        return false
        
    }
    
    func expiryFieldIsNotValid(_ entry: String?) -> Bool {
        
        guard let entry = entry else { return true }
        
        let expiry = entry.filter { !$0.isWhitespace }
        let expiryValues = expiry.split(separator: "/")
        
        let month = expiryValues[0]
        let year = expiryValues[1]
        
        if (expiryYearIsNotValid(year)) { return true }
        if (expiryMonthIsNotValid(month)) { return true }
        
        return false
    }
    
    func CVCFieldIsNotValid(_ entry: String?) -> Bool {
        
        guard let entry = entry else { return true }
        
        let cvc = entry.filter { !$0.isWhitespace }
        
        let containsNotOnlyNumbers = cvc.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil
        if (containsNotOnlyNumbers) { return true }
        
        let containsTooFewDigits = cvc.count < 3
        if (containsTooFewDigits) { return true }
        
        return false
        
    }
}
