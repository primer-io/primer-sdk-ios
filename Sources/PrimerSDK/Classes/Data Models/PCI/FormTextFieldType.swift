//
//  FormTextFieldType.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 24/01/2021.

#if canImport(UIKit)

import UIKit

enum FormTextFieldType: Equatable {
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
    case cardholderName
    case cardNumber
    case expiryDate
    case cvc

    func validate(_ text: String) -> (Bool, String, Bool) {
        switch self {
        case .accountNumber:
            return (text.isValidAccountNumber, "Account number is invalid".localized(), false)
        case .sortCode:
            return (text.count > 5, "Sort code is required".localized(), false)
        case .iban:
            if text.count < 1 {
                return (false, "IBAN is required".localized(), false)
            }
            return (text.count > 5, "IBAN is too short".localized(), false)
        case .firstName:
            return (!text.isEmpty, "First name is required".localized(), false)
        case .lastName:
            return (!text.isEmpty, "Last name is required".localized(), false)
        case .email:
            if text.count < 1 {
                return (false, "Email text field can't be empty".localized(), false)
            }

            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
            return (emailPred.evaluate(with: text), "Email value is invalid".localized(), false)
        case .addressLine1:
            return (!text.isEmpty, "Address is required".localized(), false)
        case .addressLine2:
            if !text.isEmpty { return (true, "", false) }
            return (true, "", true)
        case .city:
            return (!text.isEmpty, "City is required".localized(), false)
        case .country:
            return (!text.isEmpty, "Country is required".localized(), false)
        case .postalCode:
            return (!text.isEmpty, "Postal code is required".localized(), false)
        case .cardholderName:
            return Validation.nameFieldIsValid(text)
        case .cardNumber:
            return Validation.cardFieldIsValid(text)
        case .expiryDate:
            return Validation.expiryFieldIsValid(text)
        case .cvc:
            return Validation.CVCFieldIsValid(text)
        }
    }

    var title: String {
        switch self {
        case .accountNumber: return "Account number".localized()
        case .sortCode: return "Sort code".localized()
        case .iban: return "IBAN"
        case .firstName: return "First name".localized()
        case .lastName: return "Last name".localized()
        case .email: return "Email".localized()
        case .addressLine1: return "Address line 1".localized()
        case .addressLine2: return "Address line 2".localized()
        case .city: return "City".localized()
        case .country: return "Country".localized()
        case .postalCode: return "Postal Code".localized()
        case .cardholderName: return "Cardholder name"
        case .cardNumber: return "Card number"
        case .expiryDate: return "Expiry date"
        case .cvc: return "CVC"
        }
    }

    var placeHolder: String {
        switch self {
        case .accountNumber: return "e.g. 12345678"
        case .sortCode: return "e.g. 60-83-71"
        case .iban: return "e.g. FR14 2004 1010 0505000..."
        case .firstName: return "e.g. John"
        case .lastName: return "e.g. Doe"
        case .email: return "e.g. john@mail.com"
        case .addressLine1: return "e.g. Apartment 5, 14 Some Street".localized()
        case .addressLine2: return "(optional)"
        case .city: return "e.g. Paris"
        case .country: return "e.g. France"
        case .postalCode: return "e.g. 75001"
        case .cardholderName: return "e.g. John Doe"
        case .cardNumber: return "e.g. 4242 4242 4242 4242"
        case .expiryDate: return "e.g. 09/23"
        case .cvc: return "e.g. 123"
        }
    }

    var mask: Mask? {
        switch self {
        case .accountNumber: return Mask(pattern: "########")
        case .sortCode: return Mask(pattern: "##-##-##")
        case .iban: return Mask(pattern: "**** **** **** **********************")
        case .firstName: return nil
        case .lastName: return nil
        case .email: return nil
        case .addressLine1: return nil
        case .addressLine2: return nil
        case .city: return nil
        case .country: return nil
        case .postalCode: return nil
        case .cardholderName: return nil
        case .cardNumber: return Mask(pattern: "#### #### #### #### ###")
        case .expiryDate: return Mask(pattern: "##/##")
        case .cvc: return Mask(pattern: "####")
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
        case .cardholderName: return ""
        case .cardNumber: return ""
        case .expiryDate: return ""
        case .cvc: return ""
        }
    }
}

extension FormTextFieldType {
    var keyboardType: UIKeyboardType {
        switch self {
        case .email: return .emailAddress
        case .expiryDate: return .numberPad
        case .cardNumber: return .numberPad
        case .cvc: return .numberPad
        default: return .default
        }
    }
}

#endif
