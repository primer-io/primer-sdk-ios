//
//  FormTextFieldType.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 24/01/2021.
//
enum FormTextFieldType {
    case accountNumber(_ initialValue: String? = "")
    case sortCode(_ initialValue: String? = "")
    case iban(_ initialValue: String? = "")
    case firstName(_ initialValue: String? = "")
    case lastName(_ initialValue: String? = "")
    case email(_ initialValue: String? = "")
    case addressLine1(_ initialValue: String? = "")
    case addressLine2(_ initialValue: String? = "")
    case city(_ initialValue: String? = "")
    case country(_ initialValue: String? = "")
    case postalCode(_ initialValue: String? = "")
    
    func validate(_ text: String) -> Bool {
        switch self {
        case .accountNumber: return text.isValidAccountNumber
        case .sortCode: return text.count > 5
        case .iban: return text.count > 5
        case .firstName: return text.count > 0
        case .lastName: return text.count > 0
        case .email:
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailPred.evaluate(with: text)
        case .addressLine1: return text.count > 0
        case .addressLine2: return true
        case .city: return text.count > 0
        case .country: return text.count > 0
        case .postalCode: return text.count > 0
        }
    }
    
    var title: String {
        switch self {
        case .accountNumber: return "ACCOUNT NUMBER"
        case .sortCode: return "SORT CODE"
        case .iban: return "IBAN"
        case .firstName: return "FIRST NAME"
        case .lastName: return "LAST NAME"
        case .email: return "EMAIL"
        case .addressLine1: return "ADDRESS LINE 1"
        case .addressLine2: return "ADDRESS LINE 2"
        case .city: return "CITY"
        case .country: return "COUNTRY"
        case .postalCode: return "POSTAL CODE"
        }
    }
    
    var placeHolder: String {
        switch self {
        case .accountNumber: return "Account number"
        case .sortCode: return "Sort code"
        case .iban: return "IBAN"
        case .firstName: return "First name"
        case .lastName: return "Last name"
        case .email: return "Email"
        case .addressLine1: return "Address line 1"
        case .addressLine2: return "Address line 2"
        case .city: return "City"
        case .country: return "Country"
        case .postalCode: return "Postal code"
        }
    }
    
    var mask: Mask? {
        switch self {
        case .accountNumber: return nil
        case .sortCode: return nil
        case .iban: return Mask(pattern: "**** **** **** **** **** **** **** **** **")
        case .firstName: return nil
        case .lastName: return nil
        case .email: return nil
        case .addressLine1: return nil
        case .addressLine2: return nil
        case .city: return nil
        case .country: return nil
        case .postalCode: return nil
        }
    }
    
    var initialValue: String {
        switch self {
        case .accountNumber(let val): return val ?? ""
        case .sortCode(let val): return val ?? ""
        case .iban(let val): return val ?? ""
        case .firstName(let val): return val ?? ""
        case .lastName(let val): return val ?? ""
        case .email(let val): return val ?? ""
        case .addressLine1(let val): return val ?? ""
        case .addressLine2(let val): return val ?? ""
        case .city(let val): return val ?? ""
        case .country(let val): return val ?? ""
        case .postalCode(let val): return val ?? ""
        }
    }
}
