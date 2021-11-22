//
//  Customer.swift
//  PrimerSDK
//
//  Created by Evangelos on 22/11/21.
//

#if canImport(UIKit)

import Foundation

public struct Customer: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let homePhoneNumber: String?
    let mobilePhoneNumber: String?
    let workPhoneNumber: String?
    var billingAddress: Address?
    
    public init(
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        homePhoneNumber: String? = nil,
        mobilePhoneNumber: String? = nil,
        workPhoneNumber: String? = nil,
        billingAddress: Address? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.homePhoneNumber = homePhoneNumber
        self.mobilePhoneNumber = mobilePhoneNumber
        self.workPhoneNumber = workPhoneNumber
        self.billingAddress = billingAddress
    }
}

#endif
