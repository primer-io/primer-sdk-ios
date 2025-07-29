//
//  MerchantHeadlessStripeAchFieldsViewModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

class StripeAchFieldsViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var emailAddress: String = ""

    @Published var firstNameErrorDescription: String = ""
    @Published var lastNameErrorDescription: String = ""
    @Published var emailErrorDescription: String = ""

    @Published var isFirstNameValid: Bool = true
    @Published var isLastNameValid: Bool = true
    @Published var isEmailAddressValid: Bool = true

    var isValidForm: Bool {
        isFirstNameValid && isLastNameValid && isEmailAddressValid
    }
}
