//
//  CustomPaymentSelectionDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

// MARK: - Custom Payment Selection Demo

/// Self-contained demo showing a fully custom payment selection screen.
/// This demo handles its own session creation, PrimerCheckout initialization, and all custom UI.
@available(iOS 15.0, *)
struct CustomPaymentSelectionDemo: View, CheckoutComponentsDemo {

    // MARK: - Metadata

    static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Custom Payment Selection",
            description: "Fully custom payment screen with merchant-controlled layout, product details, and payment method display",
            tags: ["PAYMENT_CARD", "APPLE_PAY", "PAYPAL"],
            isCustom: true
        )
    }

    // MARK: - Configuration

    private let configuration: DemoConfiguration

    // MARK: - State

    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var clientToken: String?
    @State private var isLoading = true
    @State private var error: String?

    // MARK: - Theme

    /// Custom theme using demo color palette for SDK components
    private var demoTheme: PrimerCheckoutTheme {
        PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorBrand: DemoColors.primary,
                primerColorGray000: DemoColors.cardBackground,
                primerColorGray100: DemoColors.primaryBackground,
                primerColorGray200: DemoColors.border,
                primerColorGreen500: DemoColors.success,
                primerColorBackground: DemoColors.background,
                primerColorTextPrimary: DemoColors.textPrimary,
                primerColorTextSecondary: DemoColors.textSecondary,
                primerColorBorderOutlinedDefault: DemoColors.border,
                primerColorBorderOutlinedFocus: DemoColors.primary
            )
        )
    }

    // MARK: - Init

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            contentView
                .navigationBarHidden(true)
        }
        .task {
            await createSession()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            LoadingView()
        } else if let error {
            ErrorView(error: error, onRetry: { Task { await createSession() } })
        } else if let clientToken {
            PrimerCheckout(
                clientToken: clientToken,
                primerSettings: configuration.settings,
                primerTheme: demoTheme,
                scope: { checkoutScope in
                    // Override the payment method selection screen with custom content
                    // Pass checkoutScope as a parameter to access card form and checkout state
                    checkoutScope.paymentMethodSelection.screen = { selectionScope in
                        AnyView(CustomPaymentSelectionContent(
                            scope: selectionScope,
                            checkoutScope: checkoutScope,
                            onDismiss: { dismiss() }
                        ))
                    }

                    // Custom loading screen during payment processing (matches Android's checkout.loading)
                    checkoutScope.loading = {
                        AnyView(CustomProcessingOverlay())
                    }
                },
                onCompletion: { _ in dismiss() }
            )
        }
    }

    // MARK: - Session Creation

    private func createSession() async {
        isLoading = true
        error = nil

        guard let clientSession = configuration.clientSession else {
            error = "No session configuration provided - please configure session in main settings"
            isLoading = false
            return
        }

        do {
            clientToken = try await NetworkingUtils.requestClientSession(
                body: clientSession,
                apiVersion: configuration.apiVersion
            )
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Selected Payment Option

@available(iOS 15.0, *)
private enum SelectedPaymentOption: Equatable {
    case paymentMethod(CheckoutPaymentMethod)
    case card
    case none

    static func == (lhs: SelectedPaymentOption, rhs: SelectedPaymentOption) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.card, .card):
            return true
        case let (.paymentMethod(lhsMethod), .paymentMethod(rhsMethod)):
            return lhsMethod.id == rhsMethod.id
        default:
            return false
        }
    }
}

// MARK: - Demo Color Scheme

/// Warm, modern color palette for the checkout demo
/// These colors are used for demo-specific UI elements not covered by SDK design tokens
@available(iOS 15.0, *)
private enum DemoColors {
    /// Warm cream/beige background
    static let background = Color(red: 254/255, green: 245/255, blue: 236/255)

    /// Primary orange accent
    static let primary = Color(red: 249/255, green: 115/255, blue: 22/255)

    /// Light orange for highlights
    static let primaryLight = Color(red: 253/255, green: 186/255, blue: 116/255)

    /// Very light orange for backgrounds
    static let primaryBackground = Color(red: 255/255, green: 247/255, blue: 237/255)

    /// Card background - white
    static let cardBackground = Color.white

    /// Text primary - dark gray
    static let textPrimary = Color(red: 31/255, green: 41/255, blue: 55/255)

    /// Text secondary - medium gray
    static let textSecondary = Color(red: 107/255, green: 114/255, blue: 128/255)

    /// Success green
    static let success = Color(red: 34/255, green: 197/255, blue: 94/255)

    /// Border color
    static let border = Color(red: 229/255, green: 231/255, blue: 235/255)
}

// MARK: - Custom Payment Selection Content

/// AIR-style payment selection screen demonstrating the scope-based customization API.
/// Features:
/// - Custom warm cream/beige background
/// - Product info section with package details
/// - Promotional banner with rewards info
/// - Billing info section with country picker
/// - Dynamic payment methods from SDK
/// - Always-visible inline card form
/// - Promo code section
/// - Footer with total and dynamic Pay button
@available(iOS 15.0, *)
private struct CustomPaymentSelectionContent: View {
    let scope: PrimerPaymentMethodSelectionScope
    let checkoutScope: PrimerCheckoutScope
    let onDismiss: () -> Void

    @State private var selectionState = PrimerPaymentMethodSelectionState()
    @State private var cardState: StructuredCardFormState?
    @State private var selectedOption: SelectedPaymentOption = .none
    @State private var selectedBillingCountry: String? = "RS" // Default to Serbia for demo
    @State private var showPromoCodeModal = false
    @State private var appliedPromoCode: String?
    @State private var isPaymentInProgress = false
    @State private var checkoutState: PrimerCheckoutState = .initializing

    /// Card form scope for inline card form
    private var cardFormScope: DefaultCardFormScope? {
        checkoutScope.getPaymentMethodScope(DefaultCardFormScope.self)
    }

    /// Computed property to check if loading overlay should be shown
    private var isLoading: Bool {
        isPaymentInProgress || (cardState?.isLoading ?? false)
    }

    /// Extract amount from checkout state
    private var amount: Int {
        if case let .ready(totalAmount, _) = checkoutState {
            return totalAmount
        }
        return 400 // Default
    }

    /// Extract currency from checkout state
    private var currencyCode: String {
        if case let .ready(_, currency) = checkoutState {
            return currency
        }
        return "USD" // Default
    }

    var body: some View {
        ZStack {
            // Warm cream background
            DemoColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Product info section
                        productInfoSection

                        // Promotional banner
                        promotionalBanner

                        // Billing info (expandable)
                        billingInfoSection

                        // Payment methods section
                        paymentMethodsSection

                        // Inline card form section
                        cardFormSection

                        // Promo code section
                        promoCodeSection

                        // Spacer for footer
                        Color.clear.frame(height: 100)
                    }
                    .padding()
                }

                // Footer with total and pay button
                footerView
            }
            .allowsHitTesting(!isLoading)

            // Loading overlay
            if isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            observeSelectionState()
            observeCardFormState()
            observeCheckoutState()
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Loading indicator
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Processing payment...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DemoColors.textPrimary.opacity(0.9))
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button(action: {
                scope.onCancel()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(DemoColors.textPrimary)
            }

            Spacer()

            Text("Secure checkout")
                .font(.headline)
                .foregroundColor(DemoColors.textPrimary)

            Spacer()

            // Placeholder for symmetry
            Color.clear.frame(width: 24, height: 24)
        }
        .padding()
        .background(DemoColors.cardBackground)
    }

    // MARK: - Product Info Section

    private var productInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Country flag and name (dynamic based on selected billing country)
            HStack {
                if let code = selectedBillingCountry,
                   let country = CountryDataProvider.country(for: code) {
                    Text("\(country.flag) \(country.name)")
                        .font(.subheadline)
                        .foregroundColor(DemoColors.textSecondary)
                } else {
                    Text("Select a country")
                        .font(.subheadline)
                        .foregroundColor(DemoColors.textSecondary)
                }
            }
            .padding(.vertical, 8)

            Divider()
                .background(DemoColors.border)

            // Product details
            HStack(alignment: .top, spacing: 12) {
                // Product icon with orange
                RoundedRectangle(cornerRadius: 8)
                    .fill(DemoColors.primaryBackground)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(DemoColors.primary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mobile Data Package")
                        .font(.headline)
                        .foregroundColor(DemoColors.textPrimary)
                }
            }

            // Package details
            VStack(spacing: 8) {
                packageDetailRow(icon: "mappin.circle", label: "Coverage", value: selectedCountryName)
                packageDetailRow(icon: "arrow.up.arrow.down", label: "Data", value: "1 GB")
                packageDetailRow(icon: "calendar", label: "Validity", value: "3 Days")
            }
            .padding(.top, 8)
        }
        .padding()
        .background(DemoColors.cardBackground)
        .cornerRadius(16)
    }

    private var selectedCountryName: String {
        guard let code = selectedBillingCountry,
              let country = CountryDataProvider.country(for: code) else {
            return "Not selected"
        }
        return country.name
    }

    private func packageDetailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(DemoColors.textSecondary)
                .frame(width: 24)
            Text(label)
                .foregroundColor(DemoColors.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(DemoColors.textPrimary)
        }
        .font(.subheadline)
    }

    // MARK: - Promotional Banner

    private var promotionalBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.circle.fill")
                .foregroundColor(DemoColors.primary)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("You'll earn rewards from this purchase:")
                    .font(.subheadline)
                    .foregroundColor(DemoColors.textPrimary)
                Text("$0.28 USD")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DemoColors.textPrimary)
            }

            Spacer()
        }
        .padding()
        .background(DemoColors.primaryBackground)
        .cornerRadius(16)
    }

    // MARK: - Billing Info Section

    private var billingInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Billing info")
                .font(.subheadline)
                .foregroundColor(DemoColors.textSecondary)

            ThemedCountryPickerButton(
                selectedCountryCode: $selectedBillingCountry,
                placeholder: "Select billing country"
            )
        }
    }

    // MARK: - Payment Methods Section

    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pay with")
                .font(.subheadline)
                .foregroundColor(DemoColors.textSecondary)

            if selectionState.isLoading {
                ProgressView()
                    .tint(DemoColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if nonCardPaymentMethods.isEmpty {
                Text("No alternative payment methods available")
                    .font(.caption)
                    .foregroundColor(DemoColors.textSecondary)
                    .padding()
            } else {
                // Display payment methods dynamically
                ForEach(nonCardPaymentMethods, id: \.id) { method in
                    paymentMethodButton(method)
                }
            }
        }
    }

    private var nonCardPaymentMethods: [CheckoutPaymentMethod] {
        selectionState.paymentMethods.filter { $0.type != "PAYMENT_CARD" }
    }

    private func paymentMethodButton(_ method: CheckoutPaymentMethod) -> some View {
        let isSelected = {
            if case let .paymentMethod(selectedMethod) = selectedOption {
                return selectedMethod.id == method.id
            }
            return false
        }()

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedOption = .paymentMethod(method)
            }
        }) {
            HStack(spacing: 12) {
                // Payment method icon
                if let icon = method.icon {
                    Image(uiImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: iconForPaymentMethod(method.type))
                        .font(.title2)
                        .foregroundColor(DemoColors.textPrimary)
                        .frame(width: 32, height: 32)
                }

                Text(method.name)
                    .fontWeight(.medium)
                    .foregroundColor(DemoColors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DemoColors.primary)
                }
            }
            .padding()
            .background(DemoColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? DemoColors.primary : DemoColors.border, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func iconForPaymentMethod(_ type: String) -> String {
        switch type {
        case "APPLE_PAY":
            return "applelogo"
        case "PAYPAL":
            return "p.circle.fill"
        case "GOOGLE_PAY":
            return "g.circle.fill"
        default:
            return "creditcard.fill"
        }
    }

    // MARK: - Card Form Section

    private var cardFormSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pay with card")
                .font(.subheadline)
                .foregroundColor(DemoColors.textSecondary)

            // Card selection indicator
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedOption = .card
                }
            }) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(DemoColors.primary)
                    Text("Credit or Debit Card")
                        .fontWeight(.medium)
                        .foregroundColor(DemoColors.textPrimary)
                    Spacer()
                    if case .card = selectedOption {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DemoColors.primary)
                    }
                }
                .padding()
                .background(DemoColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selectedOption == .card ? DemoColors.primary : DemoColors.border, lineWidth: selectedOption == .card ? 2 : 1)
                )
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())

            // Always visible card form - using SDK's default card form view
            if let cardFormScope = cardFormScope {
                cardFormScope.DefaultCardFormView(
                    styling: PrimerFieldStyling(
                        backgroundColor: DemoColors.cardBackground,
                        borderColor: DemoColors.border,
                        cornerRadius: 12,
                        borderWidth: 1
                    )
                )
                .padding()
                .background(DemoColors.cardBackground)
                .cornerRadius(16)
                .onTapGesture {
                    // Auto-select card when user taps on form
                    if selectedOption != .card {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedOption = .card
                        }
                    }
                }
            }
        }
    }

    // MARK: - Promo Code Section

    private var promoCodeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Promo code")
                .font(.subheadline)
                .foregroundColor(DemoColors.textSecondary)

            Button(action: {
                showPromoCodeModal = true
            }) {
                HStack {
                    if let promoCode = appliedPromoCode {
                        // Show applied promo code
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DemoColors.success)
                        Text(promoCode)
                            .foregroundColor(DemoColors.textPrimary)
                            .fontWeight(.medium)
                        Spacer()
                        Button(action: {
                            appliedPromoCode = nil
                            print("[PromoCode] Removed promo code")
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DemoColors.textSecondary)
                        }
                    } else {
                        // Show "Use promo code" prompt
                        Text("Use promo code")
                            .foregroundColor(DemoColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(DemoColors.textSecondary)
                    }
                }
                .padding()
                .background(DemoColors.cardBackground)
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showPromoCodeModal) {
            PromoCodeModal(
                onApply: { code in
                    appliedPromoCode = code
                    print("[PromoCode] Applied promo code: \(code)")
                }
            )
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(DemoColors.border)

            VStack(spacing: 12) {
                // Total amount
                HStack {
                    Text("Total")
                        .font(.headline)
                        .foregroundColor(DemoColors.textPrimary)
                    Spacer()
                    Text(formattedAmount)
                        .font(.headline)
                        .foregroundColor(DemoColors.textPrimary)
                }

                // Dynamic Pay button with orange theme
                Button(action: {
                    handlePayment()
                }) {
                    HStack {
                        if case let .paymentMethod(method) = selectedOption {
                            if let icon = method.icon {
                                Image(uiImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                            }
                        }

                        Text(payButtonTitle)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isPayButtonEnabled ? DemoColors.primary : DemoColors.primaryLight)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(!isPayButtonEnabled)
            }
            .padding()
            .background(DemoColors.cardBackground)
        }
    }

    // MARK: - Computed Properties

    private var formattedAmount: String {
        // Format amount from minor units (e.g., 400 cents = $4.00)
        let majorUnits = Double(amount) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: majorUnits)) ?? "$\(majorUnits)"
    }

    private var payButtonTitle: String {
        switch selectedOption {
        case let .paymentMethod(method):
            return "Pay with \(method.name)"
        case .card:
            return "Pay \(formattedAmount)"
        case .none:
            return "Select payment method"
        }
    }

    private var isPayButtonEnabled: Bool {
        switch selectedOption {
        case .paymentMethod:
            return true
        case .card:
            return cardState?.isValid ?? false
        case .none:
            return false
        }
    }

    // MARK: - Actions

    private func handlePayment() {
        // Dismiss keyboard from all text fields
        dismissKeyboard()

        // Set loading state
        isPaymentInProgress = true

        switch selectedOption {
        case let .paymentMethod(method):
            // Trigger the payment method flow (same as tapping in default UI)
            scope.onPaymentMethodSelected(paymentMethod: method)
        case .card:
            // Submit the card form
            cardFormScope?.onSubmit()
        case .none:
            isPaymentInProgress = false
        }
    }

    /// Dismisses the keyboard by resigning first responder from all text fields
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - State Observation

    private func observeSelectionState() {
        Task {
            for await state in scope.state {
                await MainActor.run {
                    self.selectionState = state
                }
            }
        }
    }

    private func observeCardFormState() {
        guard let cardFormScope = cardFormScope else { return }
        Task {
            for await state in cardFormScope.state {
                await MainActor.run {
                    self.cardState = state
                    // Auto-select card when user starts typing
                    let hasCardInput = !state.data[.cardNumber].isEmpty ||
                        !state.data[.expiryDate].isEmpty ||
                        !state.data[.cvv].isEmpty ||
                        !state.data[.cardholderName].isEmpty
                    if hasCardInput, selectedOption == .none {
                        selectedOption = .card
                    }
                }
            }
        }
    }

    private func observeCheckoutState() {
        Task {
            for await state in checkoutScope.state {
                await MainActor.run {
                    self.checkoutState = state
                }
            }
        }
    }
}

// MARK: - Promo Code Modal

@available(iOS 15.0, *)
private struct PromoCodeModal: View {
    @SwiftUI.Environment(\.presentationMode) private var presentationMode

    let onApply: (String) -> Void

    @State private var promoCode = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header description
                Text("Enter your promo code below to apply a discount to your order.")
                    .font(.subheadline)
                    .foregroundColor(DemoColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top)

                // Promo code input
                TextField("Enter promo code", text: $promoCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal)

                // Apply button
                Button(action: {
                    if !promoCode.isEmpty {
                        onApply(promoCode)
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Apply Code")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(promoCode.isEmpty ? DemoColors.primaryLight : DemoColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(promoCode.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Promo Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

// MARK: - Custom Processing Overlay

/// Custom processing screen shown during payment processing
/// Uses the demo's orange color theme for consistency
@available(iOS 15.0, *)
private struct CustomProcessingOverlay: View {
    var body: some View {
        ZStack {
            // Warm cream background matching the demo theme
            DemoColors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DemoColors.primary))
                    .scaleEffect(2.0)

                VStack(spacing: 8) {
                    Text("Processing your payment")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(DemoColors.textPrimary)

                    Text("Please wait while we securely process your transaction...")
                        .font(.subheadline)
                        .foregroundColor(DemoColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
            }
        }
    }
}
