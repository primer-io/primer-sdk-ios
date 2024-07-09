//
//  ACHUserDetailsView.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 01.07.2024.
//

import UIKit
import SwiftUI

struct ACHUserDetailsView: View {
    @ObservedObject var viewModel: ACHUserDetailsViewModel

    // Properties
    var onSubmitPressed: () -> Void
    var onBackPressed: () -> Void

    var body: some View {

        ZStack {
            Button {
                onBackPressed()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 10, height: 10)
                        .foregroundColor(.black)
                        .padding(.leading, 15)
                    Text(viewModel.backLocalizedString)
                        .font(.system(size: 16))
                        .foregroundColor(.black)

                    Spacer()
                }
            }
        }
        .padding(.top, -3)

        VStack {
            HStack {
                Text(viewModel.payWithACHLocalizedString)
                    .font(.system(size: 20, weight: .medium))
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.title.rawValue)
                Spacer()
            }
            .padding(.init(top: 10, leading: 15, bottom: 10, trailing: 15))

            HStack {
                Text(viewModel.personalizedDetailsLocalizedString)
                    .font(.system(size: 16))
                Spacer()
            }
            .padding(.init(top: 0, leading: 15, bottom: 10, trailing: 15))

            HStack(alignment: .top) {
                CustomTextFieldView(text: $viewModel.firstName,
                                    title: viewModel.firstNameLocalizedString,
                                    isValid: viewModel.isFirstNameValid,
                                    errorDescription: viewModel.firstNameErrorDescription,
                                    infoDescription: "",
                                    accessibilityIdentifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.firstNameTextField.rawValue)

                CustomTextFieldView(text: $viewModel.lastName,
                                    title: viewModel.lastNameLocalizedString,
                                    isValid: viewModel.isLastNameValid,
                                    errorDescription: viewModel.lastNameErrorDescription,
                                    infoDescription: "",
                                    accessibilityIdentifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.lastNameTextField.rawValue)
            }
            .padding(.horizontal)
            .padding(.bottom, 5)

            CustomTextFieldView(text: $viewModel.emailAddress,
                                title: viewModel.emailAddressLocalizedString,
                                isValid: viewModel.isEmailAddressValid,
                                errorDescription: viewModel.emailErrorDescription,
                                infoDescription: viewModel.emailAddressInfoLocalizedString,
                                accessibilityIdentifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.emailAddressTextField.rawValue)
            .padding([.horizontal, .bottom], 15)

            Spacer()

            Button(action: submitAction) {
                Text(viewModel.continueButtonTitleLocalizedString)
                    .font(.system(size: 17))
                    .foregroundColor(viewModel.isValidForm ? Color.white : Color.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isValidForm ? Color.black : Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            .disabled(!viewModel.isValidForm)
            .padding(.horizontal)
            .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.submitButton.rawValue)
        }
        .disabled(viewModel.shouldDisableViews)
        .frame(height: 410)
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
                .background(Color.white)
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
