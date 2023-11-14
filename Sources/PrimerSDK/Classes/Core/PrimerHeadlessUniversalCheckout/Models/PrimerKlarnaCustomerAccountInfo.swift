//
//  PrimerKlarnaCustomerAccountInfo.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 14.11.2023.
//

import Foundation

public struct PrimerKlarnaCustomerAccountInfo {
    let accountUniqueId: String
    let accountRegistrationDate: Date
    let accountLastModified: Date
    
    public init(
        accountUniqueId: String,
        accountRegistrationDate: Date,
        accountLastModified: Date
    ) {
        self.accountUniqueId = accountUniqueId
        self.accountRegistrationDate = accountRegistrationDate
        self.accountLastModified = accountLastModified
    }
}
