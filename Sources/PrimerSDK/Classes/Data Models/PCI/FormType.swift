//
//  FormType.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 24/01/2021.
//

#if canImport(UIKit)

public enum PrimerFormType: String, CaseIterable {
    case bankAccount
    case name
    case iban
    case email
    case address
    case cardForm
}

enum FormType {
    
    case bankAccount(mandate: DirectDebitMandate, popOnComplete: Bool = false)
    case name(mandate: DirectDebitMandate, popOnComplete: Bool = false)
    case iban(mandate: DirectDebitMandate, popOnComplete: Bool = false)
    case email(mandate: DirectDebitMandate, popOnComplete: Bool = false)
    case address(mandate: DirectDebitMandate, popOnComplete: Bool = false)
    case cardForm(theme: PrimerThemeProtocol)
    
    var textFields: [[FormTextFieldType]] {
        switch self {
        case .bankAccount(let mandate, _): return [[.accountNumber(mandate.accountNumber)], [.sortCode(mandate.sortCode)]]
        case .name(let mandate, _): return [[.firstName(mandate.firstName)], [.lastName(mandate.lastName)]]
        case .iban(let mandate, _): return [[.iban(mandate.iban)]]
        case .email(let mandate, _): return [[.email(mandate.email)]]
        case .address(let mandate, _): return [
            [.addressLine1(mandate.address?.addressLine1)],
            [.addressLine2(mandate.address?.addressLine2)],
            [.city(mandate.address?.city)],
            [.postalCode(mandate.address?.postalCode)],
            [.country(mandate.address?.countryCode)]
        ]
        case .cardForm(let theme):
            switch theme.textFieldTheme {
            case .doublelined:
                return [
                    [.cardholderName],
                    [.cardNumber],
                    [.expiryDate],
                    [.cvc]
                ]
            default:
                return [
                    [.cardholderName],
                    [.cardNumber],
                    [.expiryDate, .cvc]
                ]
            }
        }
    }
    
    var topTitle: String {
        switch self {
        case .bankAccount:
            return NSLocalizedString("primer-form-type-top-title-account",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Add bank account - Form Type Navigation Bar Title (Bank account)")
            
        case .name:
            return NSLocalizedString("primer-form-type-top-title-name",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Add bank account - Form Type Navigation Bar Title (Name)")
            
        case .iban:
            return NSLocalizedString("primer-form-type-top-title-iban",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Add bank account - Form Type Navigation Bar Title (IBAN)")
            
        case .email:
            return NSLocalizedString("primer-form-type-top-title-email",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Add bank account - Form Type Navigation Bar Title (Email)")
            
        case .address:
            return NSLocalizedString("primer-form-type-top-title-address",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Add bank account - Form Type Navigation Bar Title (Address)")
            
        case .cardForm:
            return NSLocalizedString("primer-form-type-top-title-card-form",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Add new card - Form Type Navigation Bar Title (Card Form)")
        }
    }
    
    var mainTitle: String {
        switch self {
        case .bankAccount: return ""
        case .name: return ""
        case .iban: return
            NSLocalizedString("primer-form-type-main-title-sepa-direct-debit-mandate",
                              tableName: nil,
                              bundle: Bundle.primerFramework,
                              value: "",
                              comment: "SEPA Direct Debit Mandate - Form Type Main Title (Direct Debit)")
        case .email: return ""
        case .address: return ""
        case .cardForm: return ""
        }
    }
    
    var subtitle: String {
        switch self {
        case .bankAccount:
            return NSLocalizedString("primer-form-type-subtitle-use-iban",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Use IBAN instead - Form Type Subtitle (Bank account)")
            
        case .name:
            return NSLocalizedString("primer-form-type-subtitle-name",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Add bank account - Form Type Subtitle (Name)")
            
        case .iban:
            return NSLocalizedString("primer-form-type-subtitle-iban",
                                     tableName: nil,
                                     bundle: Bundle.primerFramework,
                                     value: "",
                                     comment: "Use an account number instead - Form Type Subtitle (IBAN)")
            
        case .email: return ""
        case .address: return ""
        case .cardForm: return ""
        }
    }
    
    var popOnComplete: Bool {
        switch self {
        case .bankAccount(_, let val): return val
        case .name(_, let val): return val
        case .iban(_, let val): return val
        case .email(_, let val): return val
        case .address(_, let val): return val
        case .cardForm: return false
        }
    }
}

#endif
