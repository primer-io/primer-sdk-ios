//
//  ACHUserDetailsViewModel.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 01.07.2024.
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
