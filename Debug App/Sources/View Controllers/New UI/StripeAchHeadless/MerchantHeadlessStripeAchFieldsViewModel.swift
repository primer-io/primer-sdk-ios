//
//  MerchantHeadlessStripeAchFieldsViewModel.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 03.05.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

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
