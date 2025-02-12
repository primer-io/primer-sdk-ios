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

            CustomTextFieldView(text: $viewModel.firstName,
                                isValid: viewModel.isFirstNameValid,
                                errorDescription: viewModel.firstNameErrorDescription,
                                accessibilityIdentifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.firstNameTextField.rawValue)

            CustomTextFieldView(text: $viewModel.lastName,
                                isValid: viewModel.isLastNameValid,
                                errorDescription: viewModel.lastNameErrorDescription,
                                accessibilityIdentifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.lastNameTextField.rawValue)

            CustomTextFieldView(text: $viewModel.emailAddress,
                                isValid: viewModel.isEmailAddressValid,
                                errorDescription: viewModel.emailErrorDescription,
                                accessibilityIdentifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.emailAddressTextField.rawValue)

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

struct CustomTextFieldView: View {
    @Binding var text: String

    let isValid: Bool
    let errorDescription: String
    let accessibilityIdentifier: String

    var body: some View {
        VStack(alignment: .leading) {
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .border(isValid ? Color.clear : Color.red, width: 2)
                .padding(.horizontal)
                .addAccessibilityIdentifier(identifier: accessibilityIdentifier)

            Text(errorDescription)
                .foregroundColor(.red)
                .font(.caption)
                .padding(.horizontal)
        }
    }
}
