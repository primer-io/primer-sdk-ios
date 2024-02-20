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

struct MerchantHeadlessKlarnaView: View {
    @ObservedObject var viewModel = KlarnaHeadlessPaymentViewModel()
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
            
            ForEach(viewModel.paymentCategories, id: \.id) { category in
                RadioButtonView(isSelected: selectedCategory?.id == category.id, title: category.name) {
                    selectedCategory = selectedCategory?.id == category.id ? nil : category
                }
            }
            
            KlarnaButton(title: "INITIALIZE KLARNA VIEW") {
                onInitializePressed(selectedCategory)
                initializePressed = true
            }
            
            VStack {
                DynamicUIViewRepresentable(wrapper: sharedWrapper)
                    .frame(height: 200)
                    .onReceive(sharedWrapper.$uiView) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            shouldShowKlarnaView = initializePressed
                        }
                    }
                
                if shouldShowKlarnaView {
                    KlarnaButton(title: "CONTINUE") {
                        onContinuePressed()
                        shouldDisableKlarnaViews = true
                    }
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
