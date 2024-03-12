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
    @State private var shouldDisableKlarnaViews: Bool = false
    
    var onInitializePressed: (KlarnaPaymentCategory?) -> Void
    var onContinuePressed: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(viewModel.paymentCategories, id: \.id) { category in
                KlarnaCategoryButton(sharedWrapper: sharedWrapper, isSelected: selectedCategory?.id == category.id, title: category.name) {
                    selectedCategory = selectedCategory?.id == category.id ? nil : category
                    onInitializePressed(selectedCategory)
                }
                .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.KlarnaComponent.initializeView.rawValue)
            }
            
            Spacer()
        }
        .frame(height: 450)
        .padding()
        .disabled(shouldDisableKlarnaViews)
    }
}
