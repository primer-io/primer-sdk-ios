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

    // swiftlint:disable function_body_length
    func validate(_ text: String) -> (Bool, String, Bool) {
        switch self {
        case .accountNumber:
            return (text.isValidAccountNumber,
                    NSLocalizedString("primer-form-validation-account-number-invalid",
                                      tableName: nil,
                                      bundle: Bundle.primerFramework,
                                      value: "",
                                      comment: "Account number is invalid - Form Validation"),
                    false)

        case .sortCode:
            return (text.count > 5,
                    NSLocalizedString("primer-form-validation-sort-code-required",
                                      tableName: nil,
                                      bundle: Bundle.primerFramework,
                                      value: "",
                                      comment: "Sort code is required - Form Validation"),
                    false)

        case .iban:
            if (text.count < 1) {
                return (false,
                        NSLocalizedString("primer-form-validation-iban-required",
                                          tableName: nil,
                                          bundle: Bundle.primerFramework,
                                          value: "",
                                          comment: "IBAN is required - Form Validation"),
                        false)
            }

            return (text.count > 5,
                    NSLocalizedString("primer-form-validation-iban-too-short",
                                      tableName: nil,
                                      bundle: Bundle.primerFramework,
                                      value: "",
                                      comment: "IBAN is too short - Form Validation"),
                    false)

        case .firstName:
            return (!text.isEmpty,
                    NSLocalizedString("primer-form-validation-firstname-required",
                                      tableName: nil,
                                      bundle: Bundle.primerFramework,
                                      value: "",
                                      comment: "First name is required - Form Validation"),
                    false)

        case .lastName:
            return (!text.isEmpty,
                    NSLocalizedString("primer-form-validation-lastname-required",
                                      tableName: nil,
                                      bundle: Bundle.primerFramework,
                                      value: "",
                                      comment: "Last name is required - Form Validation"),
                    false)

        case .email:
            if (text.count < 1) {
                return (false,
                        NSLocalizedString("primer-form-validation-email-required",
                                          comment: "Email text field can't be empty - Form Validation"),
                        false)
            }

            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return (emailPred.evaluate(with: text),
                    NSLocalizedString("primer-form-validation-email-invalid",
                                      tableName: nil,
                                      bundle: Bundle.primerFramework,
                                      value: "",
                                      comment: "Email value is invalid - Form Validation"),
                    false)

        case .addressLine1:
            return (!text.isEmpty,
                    NSLocalizedString("primer-form-validation-address-required",
                                      tableName: nil,
                                      bundle: Bundle.primerFramework,
                                      value: "",
                                      comment: "Address is required - Form Validation"),
                    false)
        case .addressLine2:
            if !text.isEmpty { return (true, "", false) }
            return (true, "", true)

        case .city:
            return (!text.isEmpty,
                    NSLocalizedString("primer-form-validation-city-required",
                                      tableName: nil,
                                      bundle: Bundle.primerFramework,
                                      value: "",
                                      comment: "City is required - Form Validation"),
                    false)

        case .country:
            return (!text.isEmpty,
                    NSLocalizedString("primer-form-validation-country-required",
                                      tableName: nil,
                                      bundle: Bundle.primerFramework,
                                      value: "",
                                      comment: "Country is required - Form Validation"),
                    false)

        case .postalCode:
            return (!text.isEmpty,
                    NSLocalizedString("primer-form-validation-postal-code-required",
                                      tableName: nil,
                                      bundle: Bundle.primerFramework,
                                      value: "",
                                      comment: "Postal code is required - Form Validation"),
                    false)

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
        case .accountNumber:
            return NSLocalizedString("primer-form-text-field-title-account-number",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "Account number - Form Text Field Title (Account number)")

        case .sortCode:
            return NSLocalizedString("primer-form-text-field-title-sort-code",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "Sort code - Form Text Field Title (Sort code)")

        case .iban:
            return NSLocalizedString("primer-form-text-field-title-iban",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "IBAN - Form Text Field Title (IBAN)")

        case .firstName:
            return NSLocalizedString("primer-form-text-field-title-first-name",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "First name - Form Text Field Title (First name)")

        case .lastName:
            return NSLocalizedString("primer-form-text-field-title-last-name",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "Last name - Form Text Field Title (Last name)")

        case .email:
            return NSLocalizedString("primer-form-text-field-title-email",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "Email - Form Text Field Title (Email)")

        case .addressLine1:
            return NSLocalizedString("primer-form-text-field-title-address-line-1",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "Address line 1 - Form Text Field Title (Address line 1)")

        case .addressLine2:
            return NSLocalizedString("primer-form-text-field-title-address-line-2",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "Address line 2 - Form Text Field Title (Address line 2)")

        case .city:
            return NSLocalizedString("primer-form-text-field-title-city",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "City - Form Text Field Title (City)")

        case .country:
            return NSLocalizedString("primer-form-text-field-title-country",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "Country - Form Text Field Title (Country)")

        case .postalCode:
            return NSLocalizedString("primer-form-text-field-title-postal-code",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "Postal Code - Form Text Field Title (Postal code)")

        case .cardholderName:
            return NSLocalizedString("primer-form-text-field-title-cardholder-name",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "Cardholder name - Form Text Field Title (Cardholder name)")

        case .cardNumber:
            return NSLocalizedString("primer-form-text-field-title-card-number",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "Card number - Form Text Field Title (Card number)")

        case .expiryDate:
            return NSLocalizedString("primer-form-text-field-title-expiry-date",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "Expiry date - Form Text Field Title (Expiry date)")

        case .cvc:
            return NSLocalizedString("primer-form-text-field-title-cvc",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "CVC - Form Text Field Title (CVC)")
        }
    }

    var placeHolder: String {
        switch self {
        case .accountNumber:
            return NSLocalizedString("primer-form-text-field-placeholder-account-number",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. 12345678 - Form Text Field Placeholder (Account number)")

        case .sortCode:
            return NSLocalizedString("primer-form-text-field-placeholder-sort-code",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. 60-83-71 - Form Text Field Placeholder (Sort code)")

        case .iban:
            return NSLocalizedString("primer-form-text-field-placeholder-iban",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. FR14 2004 1010 0505000... - Form Text Field Placeholder (IBAN)")

        case .firstName:
            return NSLocalizedString("primer-form-text-field-placeholder-firstname",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. John - Form Text Field Placeholder (First name)")

        case .lastName:
            return NSLocalizedString("primer-form-text-field-placeholder-lastname",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. Doe - Form Text Field Placeholder (Last name)")

        case .email:
            return NSLocalizedString("primer-form-text-field-placeholder-email",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. john@mail.com - Form Text Field Placeholder (Email)")

        case .addressLine1:
            return NSLocalizedString("primer-form-text-field-placeholder-address-line-1",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. Apartment 5, 14 Some Street - Form Text Field Placeholder (Addres line 1)")

        case .addressLine2:
            return NSLocalizedString("primer-form-text-field-placeholder-address-line-2",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "(optional) - Form Text Field Placeholder (Addres line 2)")

        case .city:
            return NSLocalizedString("primer-form-text-field-placeholder-city",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. Paris - Form Text Field Placeholder (City)")

        case .country:
            return NSLocalizedString("primer-form-text-field-placeholder-country",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. France - Form Text Field Placeholder (Country)")

        case .postalCode:
            return NSLocalizedString("primer-form-text-field-placeholder-postal-code",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. 75001 - Form Text Field Placeholder (Postal code)")

        case .cardholderName:
            return NSLocalizedString("primer-form-text-field-placeholder-cardholder",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. John Doe - Form Text Field Placeholder (Cardholder name)")

        case .cardNumber:
            return NSLocalizedString("primer-form-text-field-placeholder-cardnumber",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. 4242 4242 4242 4242 - Form Text Field Placeholder (Card number)")

        case .expiryDate:
            return NSLocalizedString("primer-form-text-field-placeholder-expiry",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. 09/23 - Form Text Field Placeholder (Expiry date)")

        case .cvc:
            return NSLocalizedString("primer-form-text-field-placeholder-cvc",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "",
                                     comment: "e.g. 123 - Form Text Field Placeholder (CVC)")
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
