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
    
    let firstNameLocalizedString = "First name"
    let lastNameLocalizedString = "Last name"
    let emailAddressLocalizedString = "Email address"
    let emailAddressInfoLocalizedString = "We'll only use this to keep you updated about your payment"
    let descriptionTextSize: CGFloat = 13
    
    var isValidForm: Bool {
        isFirstNameValid && isLastNameValid && isEmailAddressValid
    }
}
