//
//  MerchantHeadlessStripeAchFieldsView.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 03.05.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit
import SwiftUI
import PrimerSDK

struct StripeAchFieldsView: View {
    @ObservedObject var viewModel = StripeAchFieldsViewModel()
    var onSubmitPressed: () -> Void
    
    var body: some View {
        VStack {
            Text("Stripe ACH session")
                .font(.title)
                .padding(.bottom, 20)
                .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.title.rawValue)
            
            VStack(alignment: .leading) {
                TextField("First name", text: $viewModel.firstName)
                    .textFieldStyle(.roundedBorder)
                    .border(viewModel.isFirstNameValid ? Color.clear : Color.red, width: 2)
                    .padding(.horizontal)
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.firstNameTextField.rawValue)
                
                Text(viewModel.firstNameErrorDescription)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading) {
                TextField("Last name", text: $viewModel.lastName)
                    .textFieldStyle(.roundedBorder)
                    .border(viewModel.isLastNameValid ? Color.clear : Color.red, width: 2)
                    .padding(.horizontal)
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.lastNameTextField.rawValue)
                
                Text(viewModel.lastNameErrorDescription)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading) {
                TextField("Email address", text: $viewModel.emailAddress)
                    .textFieldStyle(.roundedBorder)
                    .border(viewModel.isEmailAddressValid ? Color.clear : Color.red, width: 2)
                    .padding([.horizontal])
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.emailAddressTextField.rawValue)
                
                Text(viewModel.emailErrorDescription)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding([.horizontal])
            }
            
            Button(action: submitAction) {
                Text("SUBMIT")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isValidForm ? Color.purple : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!viewModel.isValidForm)
            .padding(.horizontal)
            .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.submitButton.rawValue)
        }
    }
    
    private func submitAction() {
        onSubmitPressed()
    }
}

