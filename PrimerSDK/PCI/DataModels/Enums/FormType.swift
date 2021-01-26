//
//  FormType.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 24/01/2021.
//
enum FormType {
    case bankAccount(mandate: DirectDebitMandate, popOnComplete: Bool = false)
    case name(mandate: DirectDebitMandate, popOnComplete: Bool = false)
    case iban(mandate: DirectDebitMandate, popOnComplete: Bool = false)
    case email(mandate: DirectDebitMandate, popOnComplete: Bool = false)
    case address(mandate: DirectDebitMandate, popOnComplete: Bool = false)
    
    var textFields: [FormTextFieldType] {
        switch self {
        case .bankAccount(let mandate, _): return [.accountNumber(mandate.accountNumber), .sortCode(mandate.sortCode)]
        case .name(let mandate, _): return [.firstName(mandate.firstName), .lastName(mandate.lastName)]
        case .iban(let mandate, _): return [.iban(mandate.iban)]
        case .email(let mandate, _): return [.email(mandate.email)]
        case .address(let mandate, _): return [
            .addressLine1(mandate.address?.addressLine1),
            .addressLine2(mandate.address?.addressLine2),
            .city(mandate.address?.city),
            .postalCode(mandate.address?.postalCode),
            .country(mandate.address?.countryCode)
        ]
        }
    }
    
    var topTitle: String {
        switch self {
        case .bankAccount: return "Add bank account"
        case .name: return "Add bank account"
        case .iban: return "Add bank account"
        case .email: return "Add bank account"
        case .address: return "Add bank account"
        }
    }
    
    var mainTitle: String {
        switch self {
        case .bankAccount: return ""
        case .name: return ""
        case .iban: return "SEPA Direct Debit Mandate"
        case .email: return ""
        case .address: return ""
        }
    }
    
    var subtitle: String {
        switch self {
        case .bankAccount: return "Use IBAN instead"
        case .name: return "Add bank account"
        case .iban: return "Use an account number instead"
        case .email: return ""
        case .address: return ""
        }
    }
    
    var popOnComplete: Bool {
        switch self {
        case .bankAccount(_, let val): return val
        case .name(_, let val): return val
        case .iban(_, let val): return val
        case .email(_, let val): return val
        case .address(_, let val): return val
        }
    }
}
