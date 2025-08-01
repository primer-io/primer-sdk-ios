//
//  PrimerKlarnaCategoriesView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

struct PrimerKlarnaCategoriesView: View {
    @ObservedObject var viewModel = PrimerKlarnaCategoriesViewModel()
    @ObservedObject var sharedWrapper: SharedUIViewWrapper
    @State private var selectedCategory: KlarnaPaymentCategory?
    @State private var isButtonActive: Bool = false

    var onBackPressed: () -> Void
    var onInitializePressed: (KlarnaPaymentCategory?) -> Void
    var onContinuePressed: () -> Void
    let klarnaLogoImage = UIImage.klarnaColored ?? UIImage()
    let leftArrowImage = UIImage.leftArrow ?? UIImage()

    var body: some View {

        ZStack {
            Button {
                onBackPressed()
            } label: {
                HStack {
                    Image(uiImage: leftArrowImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                        .padding(.leading, 15)

                    Spacer()
                }
                .opacity(viewModel.showBackButton ? 1 : 0)
            }

            Image(uiImage: klarnaLogoImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 66, height: 33)
        }
        .padding(.top, -8)

        VStack(alignment: .leading, spacing: 10) {
            ForEach(viewModel.paymentCategories, id: \.id) { category in
                KlarnaCategoryButton(sharedWrapper: sharedWrapper, isSelected: selectedCategory?.id == category.id, title: category.name) {
                    selectedCategory = selectedCategory?.id == category.id ? nil : category
                    isButtonActive = selectedCategory != nil
                    onInitializePressed(selectedCategory)
                }
                .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.KlarnaComponent.initializeView.rawValue)
            }
            Spacer()
        }
        .frame(height: 450)
        .padding()
        .disabled(viewModel.shouldDisableKlarnaViews)
        .opacity(viewModel.isAuthorizing ? 0 : 1)

        Spacer()

        HStack {
            ContinueButton(isActive: $isButtonActive, title: "Continue") {
                onContinuePressed()
                viewModel.shouldDisableKlarnaViews = true
            }
            .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.KlarnaComponent.authorize.rawValue)
        }
        .padding(.horizontal, 15)
        .disabled(viewModel.shouldDisableKlarnaViews)
        .opacity(viewModel.showBackButton ? 1 : 0)
    }
}
