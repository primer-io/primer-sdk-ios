//
//  ACHUserDetailsView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
import SwiftUI

struct ACHUserDetailsView: View {
    @ObservedObject var viewModel: ACHUserDetailsViewModel

    // Properties
    var onSubmitPressed: () -> Void
    var onBackPressed: () -> Void

    var body: some View {
        VStack {
            ZStack {
                Button {
                    onBackPressed()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .foregroundColor(.blue)
                            .padding(.leading, 15)
                        Text(Strings.UserDetails.backButton)
                            .font(.system(size: 17))
                            .foregroundColor(.blue)
                            .padding(.leading, -5)

                        Spacer()
                    }
                }

                Text(String(format: Strings.ResultView.paymentTitle, "ACH"))
                    .font(.system(size: 18, weight: .medium))
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.title.rawValue)
            }
            .background(PrimerColors.swiftColor(PrimerColors.white))

            HStack {
                Text(Strings.UserDetails.subtitle)
                    .font(.system(size: 17))
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.subtitle.rawValue)
                Spacer()
            }
            .padding(.init(top: 20, leading: 15, bottom: 10, trailing: 15))

            HStack(alignment: .top) {
                CustomTextFieldView(text: $viewModel.firstName,
                                    title: Strings.UserDetails.FirstName.label,
                                    isValid: viewModel.isFirstNameValid,
                                    errorDescription: viewModel.firstNameErrorDescription,
                                    infoDescription: "",
                                    accessibilityIdentifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.firstNameTextField.rawValue)

                CustomTextFieldView(text: $viewModel.lastName,
                                    title: Strings.UserDetails.LastName.label,
                                    isValid: viewModel.isLastNameValid,
                                    errorDescription: viewModel.lastNameErrorDescription,
                                    infoDescription: "",
                                    accessibilityIdentifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.lastNameTextField.rawValue)
            }
            .padding(.horizontal)
            .padding(.bottom, 5)

            CustomTextFieldView(text: $viewModel.emailAddress,
                                title: Strings.UserDetails.EmailAddress.label,
                                isValid: viewModel.isEmailAddressValid,
                                errorDescription: viewModel.emailErrorDescription,
                                infoDescription: Strings.UserDetails.emailDisclaimer,
                                accessibilityIdentifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.emailAddressTextField.rawValue)
                .padding([.horizontal, .bottom], 15)

            Spacer()

            Button(action: submitAction) {
                ZStack {
                    if viewModel.shouldDisableViews {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium, color: UIColor.black)
                    } else {
                        Text(Strings.UserDetails.continueButton)
                            .font(.system(size: 17, weight: .medium))
                    }
                }
                .foregroundColor(viewModel.isValidForm ? Color.white : Color.gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isValidForm ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
            .disabled(!viewModel.isValidForm)
            .padding(.horizontal)
            .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.submitButton.rawValue)
        }
        .disabled(viewModel.shouldDisableViews)
        .frame(height: 380)
        .background(PrimerColors.swiftColor(PrimerColors.white))
    }

    private func submitAction() {
        onSubmitPressed()
        viewModel.shouldDisableViews = true
    }
}

struct CustomTextFieldView: View {
    @Binding var text: String

    let title: String
    let isValid: Bool
    let errorDescription: String
    let infoDescription: String
    let accessibilityIdentifier: String
    let descriptionTextSize: CGFloat = 13

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: descriptionTextSize))

            TextField("", text: $text)
                .padding(.horizontal, 10)
                .frame(height: 44)
                .background(PrimerColors.swiftColor(PrimerColors.white))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isValid ? Color.gray.opacity(0.5) : Color.red, lineWidth: 1)
                )
                .addAccessibilityIdentifier(identifier: accessibilityIdentifier)

            if !errorDescription.isEmpty {
                Text(errorDescription)
                    .lineLimit(4)
                    .foregroundColor(.red)
                    .font(.system(size: descriptionTextSize))
            } else if !infoDescription.isEmpty {
                Text(infoDescription)
                    .foregroundColor(.gray)
                    .font(.system(size: descriptionTextSize))
            }
        }
    }
}
