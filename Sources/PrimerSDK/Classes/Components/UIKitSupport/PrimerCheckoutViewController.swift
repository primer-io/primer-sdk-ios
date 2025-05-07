//
//  PrimerCheckoutViewController.swift
//
//
//  Created by Boris on 6.2.25..
//

import UIKit
import SwiftUI

/// A UIKit wrapper for the SwiftUI PrimerCheckout view demonstrating different customization options.
@available(iOS 15.0, *)
public class PrimerCheckoutViewController: UIViewController {
    private let clientToken: String
    private let onComplete: ((Result<PaymentResult, Error>) -> Void)?

    // PRESENTATION TIP: Switch between examples by commenting/uncommenting the desired example number
    private var exampleToShow = ExampleType.default
//         private var exampleToShow = ExampleType.tabLayout
//         private var exampleToShow = ExampleType.customCardForm

    enum ExampleType {
        case `default`
        case tabLayout
        case customCardForm
    }

    public init(clientToken: String, onComplete: ((Result<PaymentResult, Error>) -> Void)? = nil) {
        self.clientToken = clientToken
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupSelectedExample()
    }

    private func setupSelectedExample() {
        let rootView: AnyView

        switch exampleToShow {
        case .default:
            // EXAMPLE 1: Default Checkout Experience
            rootView = AnyView(PrimerCheckout(clientToken: clientToken))

        case .tabLayout:
            // EXAMPLE 2: Custom Tab Layout Checkout
            rootView = AnyView(
                PrimerCheckout(
                    clientToken: clientToken,
                    content: { checkoutScope in
                        AnyView(
                            VStack(spacing: 24) {
                                Text("Primer Custom Tab Experience")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding(.top, 20)

                                TabLayoutExample(scope: checkoutScope)
                                    .padding(.horizontal)
                            }
                        )
                    }
                )
            )

        case .customCardForm:
            // EXAMPLE 3: Custom Card Form Checkout
            rootView = AnyView(
                PrimerCheckout(
                    clientToken: clientToken,
                    content: { checkoutScope in
                        AnyView(
                            VStack(spacing: 16) {
                                Text("Custom Card Form Example")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding(.top, 20)

                                CustomCheckoutWithCardForm(scope: checkoutScope)
                                    .padding(.horizontal)
                            }
                        )
                    }
                )
            )
        }

        let hostingController = UIHostingController(rootView: rootView)
        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}

// MARK: - Example Components

/// Example showing a tab-based layout for payment methods.
@available(iOS 14.0, *)
struct TabLayoutExample: View {
    let scope: PrimerCheckoutScope

    @State private var paymentMethods: [any PaymentMethodProtocol] = []
    @State private var selectedTabIndex: Int = 0

    var body: some View {
        if #available(iOS 15.0, *) {
            VStack(spacing: 20) {
                if !paymentMethods.isEmpty {
                    // Tabs for payment methods
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(paymentMethods.enumerated()), id: \.offset) { index, method in
                                Button {
                                    selectedTabIndex = index
                                    Task {
                                        await scope.selectPaymentMethod(method)
                                    }
                                } label: {
                                    Text(method.name ?? "Payment")
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(selectedTabIndex == index ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedTabIndex == index ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Selected payment method content
                    if let selectedMethod = paymentMethods[safe: selectedTabIndex] {
                        selectedMethod.defaultContent()
                    }
                } else {
                    ProgressView("Loading payment methods...")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            .task {
                for await methods in scope.paymentMethods() {
                    paymentMethods = methods
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

/// Example showing a custom checkout with a custom card form
@available(iOS 14.0, *)
struct CustomCheckoutWithCardForm: View {
    let scope: PrimerCheckoutScope

    @State private var paymentMethods: [any PaymentMethodProtocol] = []
    @State private var selectedMethod: (any PaymentMethodProtocol)?

    var body: some View {
        if #available(iOS 15.0, *) {
            VStack {
                if let selectedMethod = selectedMethod {
                    // Back button
                    HStack {
                        Button {
                            Task {
                                await scope.selectPaymentMethod(nil)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Back to payment methods")
                            }
                            .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    .padding(.bottom)

                    // Show the selected payment method with custom implementation for card
                    if let cardMethod = selectedMethod as? CardPaymentMethod {
                        cardMethod.content { cardScope in
                            CustomCardFormExample(scope: cardScope)
                        }
                    } else {
                        selectedMethod.defaultContent()
                    }
                } else {
                    // Payment method selection
                    Text("Select Payment Method")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(paymentMethods.map { IdentifiablePaymentMethod($0) }) { wrapper in
                                Button {
                                    Task {
                                        await scope.selectPaymentMethod(wrapper.method)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "creditcard")
                                            .foregroundColor(.blue)

                                        Text(wrapper.method.name ?? "Payment Method")
                                            .fontWeight(.medium)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding()
            .animation(.easeInOut, value: selectedMethod != nil)
            .task {
                for await methods in scope.paymentMethods() {
                    paymentMethods = methods
                }
            }
            .task {
                for await method in scope.selectedPaymentMethod() {
                    selectedMethod = method
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

/// Custom card form example showing branded styling and enhanced validation
@available(iOS 15.0, *)
struct CustomCardFormExample: View {
    let scope: any CardPaymentMethodScope

    @State private var cardNumber: String = ""
    @State private var expiryDate: String = ""
    @State private var cvv: String = ""
    @State private var name: String = ""
    @State private var isValid: Bool = false
    @State private var isSubmitting: Bool = false

    @Environment(\.designTokens) private var tokens

    var body: some View {
        if #available(iOS 15.0, *) {
            VStack(spacing: 20) {
                // Custom branded header
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.white)
                        )

                    Text("SecureCard")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()
                }
                .padding(.bottom)

                // Card number input with custom validation indicator
                VStack(alignment: .leading, spacing: 8) {
                    Text("Card Number")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: "creditcard")
                            .foregroundColor(.blue)
                        TextField("1234 5678 9012 3456", text: $cardNumber)
                            .keyboardType(.numberPad)
                            .onChange(of: cardNumber) { newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered != newValue {
                                    cardNumber = filtered
                                }

                                // Format card number with spaces
                                let formatted = formatCardNumber(filtered)
                                if formatted != cardNumber {
                                    cardNumber = formatted
                                }

                                // Update the scope
                                scope.updateCardNumber(filtered)
                            }

                        if !cardNumber.isEmpty {
                            Image(systemName: isCardNumberValid(cardNumber) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isCardNumberValid(cardNumber) ? .green : .red)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                // Expiry date and CVV in a row
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expiry Date")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            TextField("MM/YY", text: $expiryDate)
                                .keyboardType(.numberPad)
                                .onChange(of: expiryDate) { newValue in
                                    let formatted = formatExpiryDate(newValue)
                                    if formatted != expiryDate {
                                        expiryDate = formatted
                                    }

                                    // Extract month and year
                                    let components = expiryDate.split(separator: "/")
                                    if components.count == 2 {
                                        scope.updateExpiryMonth(String(components[0]))
                                        scope.updateExpiryYear(String(components[1]))
                                    }
                                }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CVV")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.blue)
                            TextField("123", text: $cvv)
                                .keyboardType(.numberPad)
                                .onChange(of: cvv) { newValue in
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered != newValue {
                                        cvv = filtered
                                    }
                                    scope.updateCvv(filtered)
                                }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }

                // Cardholder name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cardholder Name")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.blue)
                        TextField("John Doe", text: $name)
                            .onChange(of: name) { newValue in
                                scope.updateCardholderName(newValue)
                            }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                Spacer().frame(height: 12)

                // Custom pay button
                Button {
                    isSubmitting = true
                    Task {
                        do {
                            let result = try await scope.submit()
                            print("Payment successful: \(result)")
                            isSubmitting = false
                        } catch {
                            print("Payment failed: \(error)")
                            isSubmitting = false
                        }
                    }
                } label: {
                    if #available(iOS 16.0, *) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                                Text("Processing...")
                            } else {
                                Image(systemName: "lock.shield.fill")
                                    .padding(.trailing, 8)
                                Text("Secure Checkout")
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                .disabled(!isValid || isSubmitting)
            }
            .padding()
            .task {
                for await state in scope.state() {
                    if let state = state {
                        // Update form state based on the scope's state
                        isValid = state.validationErrors.isEmpty
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }

    // Helper functions for card formatting
    private func formatCardNumber(_ number: String) -> String {
        var formatted = ""
        for (index, char) in number.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        return formatted
    }

    private func formatExpiryDate(_ date: String) -> String {
        let filtered = date.filter { $0.isNumber }
        var formatted = ""

        for (index, char) in filtered.enumerated() {
            if index == 2 {
                formatted += "/"
            }
            if index < 4 { // Limit to MM/YY format
                formatted.append(char)
            }
        }

        return formatted
    }

    private func isCardNumberValid(_ number: String) -> Bool {
        // Simplified validation for example purposes
        let digits = number.filter { $0.isNumber }
        return digits.count >= 13 && digits.count <= 19
    }
}

// MARK: - Helper Extensions

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
