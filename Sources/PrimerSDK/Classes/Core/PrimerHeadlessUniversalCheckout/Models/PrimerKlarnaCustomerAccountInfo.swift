//
//  PrimerKlarnaCustomerAccountInfo.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 14.11.2023.
//

import Foundation

struct PrimerKlarnaCustomerAccountInfo {
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
