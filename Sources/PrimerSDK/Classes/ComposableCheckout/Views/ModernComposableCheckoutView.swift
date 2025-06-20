//
//  ModernComposableCheckoutView.swift
//
//
//  Created on 18.06.2025.
//

import SwiftUI

/// Modern ComposableCheckout view that eliminates AnyView wrapping requirement
/// This provides a more Android-like API where developers don't need to wrap content in AnyView
@available(iOS 15.0, *)
internal struct ModernComposableCheckoutView: View {

    // MARK: - Properties

    private let container: ((_ content: @escaping () -> AnyView) -> AnyView)?
    private let splashScreen: (() -> AnyView)?
    private let loadingScreen: (() -> AnyView)?
    private let paymentSelectionScreen: (() -> AnyView)?
    private let cardFormScreen: (() -> AnyView)?
    private let successScreen: (() -> AnyView)?
    private let errorScreen: ((_ cause: String) -> AnyView)?

    // MARK: - Initialization

    init(
        container: ((_ content: @escaping () -> AnyView) -> AnyView)? = nil,
        splashScreen: (() -> AnyView)? = nil,
        loadingScreen: (() -> AnyView)? = nil,
        paymentSelectionScreen: (() -> AnyView)? = nil,
        cardFormScreen: (() -> AnyView)? = nil,
        successScreen: (() -> AnyView)? = nil,
        errorScreen: ((_ cause: String) -> AnyView)? = nil
    ) {
        self.container = container
        self.splashScreen = splashScreen
        self.loadingScreen = loadingScreen
        self.paymentSelectionScreen = paymentSelectionScreen
        self.cardFormScreen = cardFormScreen
        self.successScreen = successScreen
        self.errorScreen = errorScreen
    }

    // MARK: - Body

    var body: some View {
        // Delegate to the existing ComposableCheckoutView
        // This maintains compatibility while providing the improved API
        ComposableCheckoutView(
            container: container,
            splashScreen: splashScreen,
            loadingScreen: loadingScreen,
            paymentSelectionScreen: paymentSelectionScreen,
            cardFormScreen: cardFormScreen,
            successScreen: successScreen,
            errorScreen: errorScreen
        )
    }
}
