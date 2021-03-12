import UIKit

final class Validation {
    
    private static var shared = Validation()
    
    public func validateName(name: String) ->Bool {
        let nameRegex = "^\\w{1,50}$"
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
    
    static func nameFieldIsValid(_ entry: String?) -> (Bool, String, Bool) {
        guard let entry = entry else { return (false, "Name required", false ) }
        
        let name = entry.filter { !$0.isWhitespace }
        
        let nameIsEmpty = name.count < 1
        if (nameIsEmpty) { return (false, "Name is required", false ) }
        
        let nameContainsOnlyDigits = name.allSatisfy { $0.isNumber }
        if(nameContainsOnlyDigits) { return (false, "Name must contain letters", false) }
        
        return (true, "", false )
    }
    
    static func cardFieldIsValid(_ entry: String?) -> (Bool, String, Bool) {
        guard let entry = entry else { return (false, "Card number is required", false) }
        
        let number = entry.filter { !$0.isWhitespace }
        
        let containsNotOnlyNumbers = number.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil
        if (containsNotOnlyNumbers) { return (false, "Card number can only have digits", false) }
        
        let containsTooFewDigits = number.count < 16
        if (containsTooFewDigits) { return (false, "Card number is too short", false ) }
        
        let isNotALuhnNumber = !shared.luhnCheck(number)
        if (isNotALuhnNumber)  { return (false, "Card number is invalid", false ) }
        
        return (true, "", false )
    }
    
    private func expiryYearIsNotValid(_ year: String.SubSequence) -> (Bool, String, Bool) {
        guard var yearIntValue = Int(year) else { return (false, "Expiry year is required", false ) }
        yearIntValue += 2000
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let yearAlreadyPassed = yearIntValue < currentYear
        if (yearAlreadyPassed) { return (false, "Expiry date already passed", false) }
        
        return (true, "", false)
    }
    
    private func expiryMonthIsNotValid(_ month: String.SubSequence, year: String.SubSequence) -> (Bool, String, Bool) {
        guard let monthIntValue = Int(month) else { return (false, "Expiry month is required", false ) }
        
        let monthIntValueIsNotValid = monthIntValue < 1 || monthIntValue > 12
        if (monthIntValueIsNotValid) { return (false, "Expiry month is invalid", false) }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        guard var yearIntValue = Int(year) else { return (false, "Expiry year is required", false ) }
        yearIntValue += 2000
        let yearIsCurrentyYear = yearIntValue == currentYear
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let monthAlreadyPassed = monthIntValue < currentMonth && yearIsCurrentyYear
        if (monthAlreadyPassed) { return (false, "Expiry date already passed", false ) }
        
        return (true, "", false )
    }
    
    static func expiryFieldIsValid(_ entry: String?) -> (Bool, String, Bool) {
        guard let entry = entry else { return (false, "Expiry is required", false ) }
        
        let expiry = entry.filter { !$0.isWhitespace }
        let expiryValues = expiry.split(separator: "/")
        
        if (expiryValues.count != 2) { return (false, "Expiry is invalid", false ) }
        
        let month = expiryValues[0]
        let year = expiryValues[1]
        
        let yearValidation = shared.expiryYearIsNotValid(year)
        if (!yearValidation.0) { return yearValidation }
        
        let monthValidation = shared.expiryMonthIsNotValid(month, year: year)
        if (!monthValidation.0) { return monthValidation }
        
        return (true, "", false)
    }
    
    static func CVCFieldIsValid(_ entry: String?) -> (Bool, String, Bool) {
        guard let entry = entry else { return (false, "CVC is required", false) }
        
        let cvc = entry.filter { !$0.isWhitespace }
        
        let containsNotOnlyNumbers = cvc.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil
        if (containsNotOnlyNumbers) { return (false, "CVC is invalid", false ) }
        
        let containsTooFewDigits = cvc.count < 3
        if (containsTooFewDigits) { return (false, "CVC is too short", false ) }
        
        return (true, "", false )
    }
}
