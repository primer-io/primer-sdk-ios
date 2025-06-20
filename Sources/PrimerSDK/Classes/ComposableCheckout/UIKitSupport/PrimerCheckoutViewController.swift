//
//  PrimerCheckoutViewController.swift
//
//
//  Created by Boris on 6.2.25..
//

// swiftlint:disable file_length

import UIKit
import SwiftUI

/// A UIKit wrapper for the SwiftUI PrimerCheckout view demonstrating different customization options.
@available(iOS 15.0, *)
public class PrimerCheckoutViewController: UIViewController {
    private let clientToken: String
    private let onComplete: ((Result<PaymentResult, Error>) -> Void)?

    // PRESENTATION TIP: Switch between examples by commenting/uncommenting the desired example number
    private var exampleToShow = ExampleType.default
    //     private var exampleToShow = ExampleType.tabLayout
    //     private var exampleToShow = ExampleType.customCardForm
    //     private var exampleToShow = ExampleType.gridLayout
    //     private var exampleToShow = ExampleType.listLayout
    //     private var exampleToShow = ExampleType.accordionLayout
    //     private var exampleToShow = ExampleType.modalSheet
    //     private var exampleToShow = ExampleType.segmentedControl
    //     private var exampleToShow = ExampleType.mixedLayout

    enum ExampleType {
        case `default`
        case tabLayout
        case customCardForm
        case gridLayout
        case listLayout
        case accordionLayout
        case modalSheet
        case segmentedControl
        case mixedLayout
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

        // Configure Primer with the client token
        // Note: Configuration is handled within PrimerCheckout component

        setupSelectedExample()
    }

    // swiftlint:disable:next function_body_length
    private func setupSelectedExample() {
        let rootView: AnyView

        switch exampleToShow {
        case .default:
            // EXAMPLE 1: Default Checkout Experience
            rootView = AnyView(PrimerCheckout(clientToken: clientToken))

        case .tabLayout:
            // EXAMPLE 2: Custom Tab Layout Checkout
            rootView = AnyView(
                VStack(spacing: 24) {
                    Text("Primer Custom Tab Experience")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    PrimerCheckout(clientToken: clientToken)
                        .padding(.horizontal)
                }
            )

        case .customCardForm:
            // EXAMPLE 3: Custom Card Form Checkout
            rootView = AnyView(
                VStack(spacing: 16) {
                    Text("Custom Card Form Example")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    // Use PrimerCheckout with custom content
                    PrimerCheckout(clientToken: clientToken)
                }
            )

        case .gridLayout:
            // EXAMPLE 4: Grid Layout with Payment Methods
            rootView = AnyView(
                VStack(spacing: 16) {
                    Text("Grid Layout Example")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    // Use PrimerCheckout with custom payment selection
                    PrimerCheckout(clientToken: clientToken)
                }
            )

        case .listLayout:
            // EXAMPLE 5: List Layout with Detailed Payment Methods
            rootView = AnyView(
                VStack(spacing: 16) {
                    Text("List Layout Example")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    PrimerCheckout(clientToken: clientToken)
                }
            )

        case .accordionLayout:
            // EXAMPLE 6: Accordion Layout for Payment Methods
            rootView = AnyView(
                VStack(spacing: 16) {
                    Text("Accordion Layout Example")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    PrimerCheckout(clientToken: clientToken)
                }
            )

        case .modalSheet:
            // EXAMPLE 7: Modal Sheet Presentation
            rootView = AnyView(
                VStack(spacing: 16) {
                    Text("Modal Sheet Example")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    PrimerCheckout(clientToken: clientToken)
                }
            )

        case .segmentedControl:
            // EXAMPLE 8: Segmented Control Layout
            rootView = AnyView(
                VStack(spacing: 16) {
                    Text("Segmented Control Example")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    PrimerCheckout(clientToken: clientToken)
                }
            )

        case .mixedLayout:
            // EXAMPLE 9: Mixed Layout Combining Multiple Styles
            rootView = AnyView(
                VStack(spacing: 16) {
                    Text("Mixed Layout Example")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    PrimerCheckout(clientToken: clientToken)
                }
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

                    // Show the selected payment method
                    selectedMethod.defaultContent()
                } else {
                    // Payment method selection
                    Text("Select Payment Method")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(paymentMethods.map { PaymentMethodWrapper($0) }) { wrapper in
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
    let scope: any CardFormScope

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

                                    // Update expiry date in scope
                                    scope.updateExpiryDate(formatted)
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
                    scope.submit()
                    // In a real implementation, you would handle the async result
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isSubmitting = false
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
                    // Update form state based on the scope's state
                    isValid = state.isSubmitEnabled
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

/// Example showing a grid layout for payment methods
@available(iOS 15.0, *)
struct GridLayoutExample: View {
    let scope: PrimerCheckoutScope

    @State private var paymentMethods: [any PaymentMethodProtocol] = []
    @State private var selectedMethod: (any PaymentMethodProtocol)?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 20) {
            if let selectedMethod = selectedMethod {
                // Show selected method
                VStack {
                    HStack {
                        Button {
                            Task {
                                await scope.selectPaymentMethod(nil)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Back")
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom)

                    selectedMethod.defaultContent()
                }
            } else {
                // Grid of payment methods
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(paymentMethods.map { PaymentMethodWrapper($0) }) { wrapper in
                            Button {
                                Task {
                                    await scope.selectPaymentMethod(wrapper.method)
                                }
                            } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.blue)

                                    Text(wrapper.method.name ?? "Payment")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
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
    }
}

/// Example showing a detailed list layout
@available(iOS 15.0, *)
struct ListLayoutExample: View {
    let scope: PrimerCheckoutScope

    @State private var paymentMethods: [any PaymentMethodProtocol] = []
    @State private var selectedMethod: (any PaymentMethodProtocol)?

    var body: some View {
        VStack(spacing: 16) {
            if let selectedMethod = selectedMethod {
                // Show selected method
                VStack {
                    HStack {
                        Button {
                            Task {
                                await scope.selectPaymentMethod(nil)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Back")
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom)

                    selectedMethod.defaultContent()
                }
            } else {
                // List of payment methods with details
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(paymentMethods.map { PaymentMethodWrapper($0) }) { wrapper in
                            Button {
                                Task {
                                    await scope.selectPaymentMethod(wrapper.method)
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "creditcard.fill")
                                                .foregroundColor(.blue)
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(wrapper.method.name ?? "Payment Method")
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text("Secure and fast payment")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
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
    }
}

/// Example showing accordion-style collapsible payment methods
@available(iOS 15.0, *)
struct AccordionLayoutExample: View {
    let scope: PrimerCheckoutScope

    @State private var paymentMethods: [any PaymentMethodProtocol] = []
    @State private var expandedMethodId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(paymentMethods.map { PaymentMethodWrapper($0) }) { wrapper in
                    VStack(spacing: 0) {
                        // Accordion header
                        Button {
                            withAnimation(.spring()) {
                                if expandedMethodId == wrapper.id {
                                    expandedMethodId = nil
                                } else {
                                    expandedMethodId = wrapper.id
                                    Task {
                                        await scope.selectPaymentMethod(wrapper.method)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.blue)

                                Text(wrapper.method.name ?? "Payment Method")
                                    .fontWeight(.medium)

                                Spacer()

                                Image(systemName: expandedMethodId == wrapper.id ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Accordion content
                        if expandedMethodId == wrapper.id {
                            wrapper.method.defaultContent()
                                .padding()
                                .background(Color(.systemGray6).opacity(0.5))
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .cornerRadius(8)
                }
            }
        }
        .task {
            for await methods in scope.paymentMethods() {
                paymentMethods = methods
            }
        }
    }
}

/// Example showing modal sheet presentation
@available(iOS 15.0, *)
struct ModalSheetExample: View {
    let scope: PrimerCheckoutScope

    @State private var paymentMethods: [any PaymentMethodProtocol] = []
    @State private var showingPaymentSheet = false
    @State private var selectedMethod: (any PaymentMethodProtocol)?

    var body: some View {
        VStack(spacing: 20) {
            Text("Ready to checkout?")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Total: $99.99")
                .font(.title2)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                showingPaymentSheet = true
            } label: {
                Text("Choose Payment Method")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .sheet(isPresented: $showingPaymentSheet) {
            NavigationView {
                VStack {
                    if let selectedMethod = selectedMethod {
                        selectedMethod.defaultContent()
                            .navigationTitle(selectedMethod.name ?? "Payment")
                            .navigationBarItems(
                                leading: Button("Back") {
                                    Task {
                                        await scope.selectPaymentMethod(nil)
                                    }
                                }
                            )
                    } else {
                        List(paymentMethods.map { PaymentMethodWrapper($0) }) { wrapper in
                            Button {
                                Task {
                                    await scope.selectPaymentMethod(wrapper.method)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                        .foregroundColor(.blue)
                                    Text(wrapper.method.name ?? "Payment")
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .navigationTitle("Payment Methods")
                        .navigationBarItems(
                            trailing: Button("Cancel") {
                                showingPaymentSheet = false
                            }
                        )
                    }
                }
            }
        }
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
    }
}

/// Example showing segmented control for payment method categories
@available(iOS 15.0, *)
struct SegmentedControlExample: View {
    let scope: PrimerCheckoutScope

    @State private var paymentMethods: [any PaymentMethodProtocol] = []
    @State private var selectedCategory = "Cards"
    @State private var selectedMethod: (any PaymentMethodProtocol)?

    let categories = ["Cards", "Wallets", "Bank", "Other"]

    var body: some View {
        VStack(spacing: 20) {
            if let selectedMethod = selectedMethod {
                // Show selected method
                VStack {
                    HStack {
                        Button {
                            Task {
                                await scope.selectPaymentMethod(nil)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Back")
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom)

                    selectedMethod.defaultContent()
                }
            } else {
                // Segmented control
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Filtered payment methods
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredMethods) { wrapper in
                            Button {
                                Task {
                                    await scope.selectPaymentMethod(wrapper.method)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: iconForCategory(selectedCategory))
                                        .foregroundColor(.blue)
                                        .frame(width: 30)

                                    Text(wrapper.method.name ?? "Payment")
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
                    .padding(.horizontal)
                }
            }
        }
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
    }

    fileprivate var filteredMethods: [PaymentMethodWrapper] {
        // In a real implementation, you would filter by actual category
        // For demo purposes, we'll show all methods for each category
        paymentMethods.map { PaymentMethodWrapper($0) }
    }

    func iconForCategory(_ category: String) -> String {
        switch category {
        case "Cards": return "creditcard.fill"
        case "Wallets": return "wallet.pass.fill"
        case "Bank": return "building.columns.fill"
        default: return "dollarsign.circle.fill"
        }
    }
}

/// Example showing a mixed layout combining multiple UI patterns
@available(iOS 15.0, *)
struct MixedLayoutExample: View {
    let scope: PrimerCheckoutScope

    @State private var paymentMethods: [any PaymentMethodProtocol] = []
    @State private var selectedMethod: (any PaymentMethodProtocol)?
    @State private var showSavedCards = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let selectedMethod = selectedMethod {
                    // Show selected method
                    VStack {
                        HStack {
                            Button {
                                Task {
                                    await scope.selectPaymentMethod(nil)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.left")
                                    Text("Back")
                                }
                            }
                            Spacer()
                        }
                        .padding(.bottom)

                        selectedMethod.defaultContent()
                    }
                } else {
                    // Mixed layout sections

                    // Section 1: Saved Cards (Collapsible)
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation {
                                showSavedCards.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Saved Cards")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: showSavedCards ? "chevron.up" : "chevron.down")
                            }
                            .foregroundColor(.primary)
                        }

                        if showSavedCards {
                            // Horizontal scroll for saved cards
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<3) { _ in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Image(systemName: "creditcard.fill")
                                                    .foregroundColor(.white)
                                                Spacer()
                                                Text("VISA")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }

                                            Text("•••• •••• •••• 4242")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))

                                            Text("Expires 12/24")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        .padding()
                                        .frame(width: 200, height: 120)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue, .purple]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(12)
                                        .onTapGesture {
                                            // Select saved card
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // Section 2: Popular Payment Methods (Grid)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Popular Methods")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(paymentMethods.prefix(3).map { PaymentMethodWrapper($0) }) { wrapper in
                                Button {
                                    Task {
                                        await scope.selectPaymentMethod(wrapper.method)
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(wrapper.method.name ?? "Pay")
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    // Section 3: All Payment Methods (List)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Payment Methods")
                            .font(.headline)

                        ForEach(paymentMethods.map { PaymentMethodWrapper($0) }) { wrapper in
                            Button {
                                Task {
                                    await scope.selectPaymentMethod(wrapper.method)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "creditcard")
                                        .foregroundColor(.blue)
                                    Text(wrapper.method.name ?? "Payment")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(PlainButtonStyle())

                            if wrapper.id != paymentMethods.map({ PaymentMethodWrapper($0) }).last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding()
        }
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
    }
}

// Helper wrapper to make payment methods identifiable for ForEach
private struct PaymentMethodWrapper: Identifiable {
    let id = UUID().uuidString
    let method: any PaymentMethodProtocol

    init(_ method: any PaymentMethodProtocol) {
        self.method = method
    }
}

// MARK: - Helper Extensions

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// swiftlint:enable file_length
