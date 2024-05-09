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

//let publishableKey = "pk_test_51MoI84BvedTI81V7r8h9B1XSl7lqU5rEdZHx8N6qoNeXDyyhUq8ziBgWXyMlO3bPADYRdAiYFQJg51fWN784pIBH00Y5YTas27"
//
//func getParams() -> Params {
//    return Params(publishableKey: publishableKey,
//                  clientSecret: "pi_3P86AgBvedTI81V719xwKkhz_secret_izeuhjFqW6ibJkjvPVBcvsGNL",
//                  returnUrl: "primer://merchant",
//                  fullName: fullName,
//                  emailAddress: emailAddress)
//}

struct Params {
    var publishableKey: String
    var clientSecret: String
    var returnUrl: String
    var fullName: String
    var emailAddress: String
}
