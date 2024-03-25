//
//  MerchantHeadlessKlarnaView.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 19.02.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation
import SwiftUI
import PrimerSDK

struct MerchantHeadlessKlarnaInitializationView: View {
    @ObservedObject var viewModel = MerchantHeadlessKlarnaInitializationViewModel()
    @ObservedObject var sharedWrapper: SharedUIViewWrapper

    @State private var selectedCategory: KlarnaPaymentCategory?
    @State private var shouldShowKlarnaView = false
    @State private var initializePressed: Bool = false
    @State private var shouldDisableKlarnaViews: Bool = false

    var onInitializePressed: (KlarnaPaymentCategory?) -> Void
    var onContinuePressed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Klarna session")
                .font(.title)
                .fontWeight(.semibold)
                .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.KlarnaComponent.title.rawValue)

            ForEach(viewModel.paymentCategories, id: \.id) { category in
                RadioButtonView(isSelected: selectedCategory?.id == category.id, title: category.name) {
                    selectedCategory = selectedCategory?.id == category.id ? nil : category
                }
            }

            KlarnaButton(title: "INITIALIZE KLARNA VIEW") {
                onInitializePressed(selectedCategory)
                initializePressed = true
            }
            .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.KlarnaComponent.initializeView.rawValue)

            VStack {
                DynamicUIViewRepresentable(wrapper: sharedWrapper)
                    .frame(height: 200)
                    .onReceive(sharedWrapper.$uiView) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            shouldShowKlarnaView = initializePressed
                        }
                    }
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.KlarnaComponent.paymentViewContainer.rawValue)

                if shouldShowKlarnaView {
                    KlarnaButton(title: "CONTINUE") {
                        onContinuePressed()
                        shouldDisableKlarnaViews = true
                    }
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.KlarnaComponent.authorize.rawValue)
                }
            }

        }
        .padding()
        .disabled(shouldDisableKlarnaViews)
        Spacer()

        if viewModel.showMessage {
            SnackbarView(message: viewModel.snackBarMessage)
                .animation(.easeInOut, value: viewModel.showMessage)
                .transition(.move(edge: .bottom))
        }
    }
}
