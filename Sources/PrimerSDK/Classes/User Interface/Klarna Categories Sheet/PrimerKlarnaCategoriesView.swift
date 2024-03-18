//
//  PrimerKlarnaCategoriesView.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 08.03.2024.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct PrimerKlarnaCategoriesView: View {
    @ObservedObject var viewModel = PrimerKlarnaCategoriesViewModel()
    @ObservedObject var sharedWrapper: SharedUIViewWrapper
    @State private var selectedCategory: KlarnaPaymentCategory?
    @State private var isButtonActive: Bool = false

    var onBackPressed: () -> Void
    var onInitializePressed: (KlarnaPaymentCategory?) -> Void
    var onContinuePressed: () -> Void
    let klarnaLogoImage = UIImage(named: "klarna-logo-colored", in: Bundle.primerResources, compatibleWith: nil) ?? UIImage()
    let leftArrowImage = UIImage(named: "arrow-left", in: Bundle.primerResources, compatibleWith: nil) ?? UIImage()

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
        }
        .padding(.horizontal, 15)
        .disabled(viewModel.shouldDisableKlarnaViews)
        .opacity(viewModel.showBackButton ? 1 : 0)
    }
}
