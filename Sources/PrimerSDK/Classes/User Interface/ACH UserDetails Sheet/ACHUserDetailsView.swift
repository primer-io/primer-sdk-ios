//
//  ACHUserDetailsView.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 01.07.2024.
//

import UIKit
import SwiftUI

struct StripeAchFieldsView: View {
    @ObservedObject var viewModel = StripeAchFieldsViewModel()
    
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
                    Text("Back")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    
                    Spacer()
                }
            }
        }
        .padding(.top, -3)
        
        VStack {
            HStack {
                Text("Pay with ACH")
                    .font(.system(size: 20, weight: .medium))
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.title.rawValue)
                Spacer()
            }
            .padding(.init(top: 10, leading: 15, bottom: 10, trailing: 15))
            
            HStack {
                Text("Your personal details")
                    .font(.system(size: 16))
                Spacer()
            }
            .padding(.init(top: 0, leading: 15, bottom: 10, trailing: 15))
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.firstNameLocalizedString)
                        .font(.system(size: viewModel.descriptionTextSize))
                    
                    TextField("", text: $viewModel.firstName)
                        .padding(.horizontal, 10)
                        .frame(height: 44)
                        .background(Color.white)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(viewModel.isFirstNameValid ? Color.gray.opacity(0.5) : Color.red, lineWidth: 1)
                        )
                        .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.firstNameTextField.rawValue)
                    
                    if !viewModel.firstNameErrorDescription.isEmpty {
                        Text(viewModel.firstNameErrorDescription)
                            .lineLimit(4)
                            .foregroundColor(.red)
                            .font(.system(size: viewModel.descriptionTextSize))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.lastNameLocalizedString)
                        .font(.system(size: viewModel.descriptionTextSize))
                    
                    TextField("", text: $viewModel.lastName)
                        .padding(.horizontal, 10)
                        .frame(height: 44)
                        .background(Color.white)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(viewModel.isLastNameValid ? Color.gray.opacity(0.5) : Color.red, lineWidth: 1)
                        )
                        .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.lastNameTextField.rawValue)
                    
                    if !viewModel.lastNameErrorDescription.isEmpty {
                        Text(viewModel.lastNameErrorDescription)
                            .lineLimit(4)
                            .foregroundColor(.red)
                            .font(.system(size: viewModel.descriptionTextSize))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.emailAddressLocalizedString)
                    .font(.system(size: viewModel.descriptionTextSize))
                
                TextField("", text: $viewModel.emailAddress)
                    .padding(.horizontal, 10)
                    .frame(height: 44)
                    .background(Color.white)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(viewModel.isEmailAddressValid ? Color.gray.opacity(0.5) : Color.red, lineWidth: 1)
                    )
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.StripeAchUserDetailsComponent.emailAddressTextField.rawValue)
                
                if viewModel.emailErrorDescription.isEmpty {
                    Text(viewModel.emailAddressInfoLocalizedString)
                        .foregroundColor(.gray)
                        .font(.system(size: viewModel.descriptionTextSize))
                } else {
                    Text(viewModel.emailErrorDescription)
                        .lineLimit(4)
                        .foregroundColor(.red)
                        .font(.system(size: viewModel.descriptionTextSize))
                }
            }
            .padding([.horizontal, .bottom], 15)
            
            Spacer()
            
            Button(action: submitAction) {
                Text("Continue")
                    .font(.headline)
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
        .frame(height: 410)
    }
    
    private func submitAction() {
        onSubmitPressed()
    }
}
