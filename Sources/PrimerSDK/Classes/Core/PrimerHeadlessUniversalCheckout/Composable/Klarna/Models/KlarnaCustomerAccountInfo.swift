//
//  KlarnaCustomerAccountInfo.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.01.2024.
//

import Foundation

struct KlarnaCustomerAccountInfo {
    let accountUniqueId: String
    let accountRegistrationDate: Date
    let accountLastModified: Date
    
    init?(
        accountUniqueId: String,
        accountRegistrationDate: Date?,
        accountLastModified: Date?
    ) {
        guard
            let accountRegistrationDate = accountRegistrationDate,
            let accountLastModified = accountLastModified
        else {
            return nil
        }
        self.accountUniqueId = accountUniqueId
        self.accountRegistrationDate = accountRegistrationDate
        self.accountLastModified = accountLastModified
    }
}

// MARK: - Equatable
extension KlarnaCustomerAccountInfo: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.accountUniqueId == rhs.accountUniqueId &&
        lhs.accountLastModified == rhs.accountLastModified &&
        lhs.accountRegistrationDate == rhs.accountRegistrationDate
    }
}
