//
//  DirectDebitMandate.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 18/01/2021.
//

#if canImport(UIKit)

struct DirectDebitMandate {
    var firstName, lastName, email, iban, accountNumber, sortCode: String?
    var address: Address?
}

#endif
