//
//  PrimerCheckoutViewController_Migrated.swift
//
//
//  Migrated to use new Primer.ComposableCheckout API
//

// swiftlint:disable file_length

import UIKit
import SwiftUI

/// A UIKit wrapper for the SwiftUI Primer.ComposableCheckout view demonstrating different customization options.
/// This version uses the NEW API that matches Android.
@available(iOS 15.0, *)
public class PrimerCheckoutViewController_Migrated: UIViewController {
    private let clientToken: String
    private let onComplete: ((Result<PaymentResult, Error>) -> Void)?
    
    // PRESENTATION TIP: Switch between examples by commenting/uncommenting the desired example number
    private var exampleToShow = ExampleType.default
    //     private var exampleToShow = ExampleType.customCardForm
    //     private var exampleToShow = ExampleType.customPaymentSelection
    //     private var exampleToShow = ExampleType.customContainer
    //     private var exampleToShow = ExampleType.fullCustomization
    
    enum ExampleType {
        case `default`
        case customCardForm
        case customPaymentSelection
        case customContainer
        case fullCustomization
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
        
        // Configure Primer with the client token (NEW API)
        Primer.configure(clientToken: clientToken)
        
        setupSelectedExample()
    }
    
    private func setupSelectedExample() {
        let rootView: AnyView
        
        switch exampleToShow {
        case .default:
            // EXAMPLE 1: Default Checkout Experience
            rootView = AnyView(
                Primer.ComposableCheckout()
            )
            
        case .customCardForm:
            // EXAMPLE 2: Custom Card Form
            rootView = AnyView(
                Primer.ComposableCheckout(
                    cardFormScreen: {
                        CustomCardFormView()
                    }
                )
            )
            
        case .customPaymentSelection:
            // EXAMPLE 3: Custom Payment Selection
            rootView = AnyView(
                Primer.ComposableCheckout(
                    paymentSelectionScreen: {
                        CustomPaymentSelectionView()
                    }
                )
            )
            
        case .customContainer:
            // EXAMPLE 4: Custom Container
            rootView = AnyView(
                Primer.ComposableCheckout(
                    container: { content in
                        NavigationView {
                            content()
                                .navigationTitle("Secure Checkout")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                )
            )
            
        case .fullCustomization:
            // EXAMPLE 5: Full Customization
            rootView = AnyView(
                Primer.ComposableCheckout(
                    container: { content in
                        VStack {
                            // Custom header
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.green)
                                Text("Secure Checkout")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            
                            content()
                        }
                    },
                    splashScreen: {
                        CustomSplashScreen()
                    },
                    loadingScreen: {
                        CustomLoadingScreen()
                    },
                    paymentSelectionScreen: {
                        CustomPaymentSelectionView()
                    },
                    cardFormScreen: {
                        CustomCardFormView()
                    },
                    successScreen: {
                        CustomSuccessScreen()
                    },
                    errorScreen: { errorMessage in
                        CustomErrorScreen(message: errorMessage)
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

// MARK: - Custom Screen Examples

/// Custom Card Form using the NEW scope-based API
@available(iOS 15.0, *)
struct CustomCardFormView: View {
    @State private var isSubmitting = false
    
    var body: some View {
        AsyncScopeView { checkoutScope, cardFormScope, paymentSelectionScope in
            VStack(spacing: 24) {
                // Custom header
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
                    
                    Text("SecureCard Payment")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Card Details Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Card Information")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                // Using the NEW scope extension functions
                                cardFormScope.PrimerCardNumberInput()
                                
                                HStack(spacing: 12) {
                                    cardFormScope.PrimerExpiryDateInput()
                                    cardFormScope.PrimerCvvInput()
                                }
                                
                                cardFormScope.PrimerCardholderNameInput()
                            }
                            .padding(.horizontal)
                        }
                        
                        // Security Notice
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Secure Payment")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("Your card details are encrypted and protected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        // Custom styled submit button
                        cardFormScope.PrimerSubmitButton(text: "Complete Payment")
                            .padding(.horizontal)
                            .padding(.bottom)
                    }
                }
            }
            .background(Color(.systemBackground))
        }
    }
}

/// Custom Payment Selection using the NEW API
@available(iOS 15.0, *)
struct CustomPaymentSelectionView: View {
    var body: some View {
        AsyncScopeView { checkoutScope, cardFormScope, paymentSelectionScope in
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Choose Payment Method")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select your preferred payment option")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                
                // Using the built-in payment selection screen
                paymentSelectionScope.PrimerPaymentMethodSelectionScreen()
            }
        }
    }
}

/// Custom Splash Screen
@available(iOS 15.0, *)
struct CustomSplashScreen: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Animated logo
            Image(systemName: "creditcard.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("Initializing Secure Checkout")
                .font(.title3)
                .fontWeight(.medium)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            isAnimating = true
        }
    }
}

/// Custom Loading Screen
@available(iOS 15.0, *)
struct CustomLoadingScreen: View {
    @State private var loadingText = "Loading payment methods"
    @State private var dotCount = 0
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .rotationEffect(.degrees(Double(dotCount) * 120))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: dotCount)
            }
            
            Text(loadingText + String(repeating: ".", count: dotCount % 4))
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                dotCount += 1
            }
        }
    }
}

/// Custom Success Screen
@available(iOS 15.0, *)
struct CustomSuccessScreen: View {
    @State private var checkmarkScale: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 32) {
            // Animated checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(checkmarkScale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: checkmarkScale)
            }
            
            VStack(spacing: 16) {
                Text("Payment Successful!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Thank you for your purchase")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button("Continue Shopping") {
                // Handle continue action
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            checkmarkScale = 1.0
        }
    }
}

/// Custom Error Screen
@available(iOS 15.0, *)
struct CustomErrorScreen: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)
            
            VStack(spacing: 16) {
                Text("Payment Failed")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button("Try Again") {
                    // Handle retry
                }
                .buttonStyle(.borderedProminent)
                
                Button("Use Different Payment Method") {
                    // Handle change payment method
                }
                .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Advanced Examples

/// Example showing how to build a completely custom checkout flow
@available(iOS 15.0, *)
public struct CompletelyCustomCheckoutExample: View {
    @State private var currentStep = CheckoutStep.selectPayment
    
    enum CheckoutStep {
        case selectPayment
        case enterCardDetails
        case processing
        case complete
    }
    
    public init() {
        // Configure Primer once
        Primer.configure(clientToken: "your_token_here")
    }
    
    public var body: some View {
        // Using the new API with full customization
        Primer.ComposableCheckout(
            container: { content in
                VStack(spacing: 0) {
                    // Custom progress indicator
                    ProgressIndicator(currentStep: currentStep)
                        .padding()
                    
                    Divider()
                    
                    // The actual checkout content
                    content()
                }
            },
            paymentSelectionScreen: {
                // Custom payment selection with grid layout
                GridPaymentSelectionView(onStepChange: { step in
                    currentStep = step
                })
            },
            cardFormScreen: {
                // Custom card form with inline validation
                InlineValidationCardForm(onStepChange: { step in
                    currentStep = step
                })
            },
            successScreen: {
                // Custom success with confetti
                ConfettiSuccessScreen()
            }
        )
    }
}

/// Progress indicator for checkout steps
@available(iOS 15.0, *)
struct ProgressIndicator: View {
    let currentStep: CompletelyCustomCheckoutExample.CheckoutStep
    
    var body: some View {
        HStack(spacing: 20) {
            StepCircle(
                number: 1,
                title: "Select",
                isActive: currentStep == .selectPayment,
                isCompleted: stepNumber(currentStep) > 1
            )
            
            StepLine(isActive: stepNumber(currentStep) > 1)
            
            StepCircle(
                number: 2,
                title: "Details",
                isActive: currentStep == .enterCardDetails,
                isCompleted: stepNumber(currentStep) > 2
            )
            
            StepLine(isActive: stepNumber(currentStep) > 2)
            
            StepCircle(
                number: 3,
                title: "Complete",
                isActive: currentStep == .complete,
                isCompleted: currentStep == .complete
            )
        }
        .frame(height: 60)
    }
    
    private func stepNumber(_ step: CompletelyCustomCheckoutExample.CheckoutStep) -> Int {
        switch step {
        case .selectPayment: return 1
        case .enterCardDetails, .processing: return 2
        case .complete: return 3
        }
    }
}

@available(iOS 15.0, *)
struct StepCircle: View {
    let number: Int
    let title: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive || isCompleted ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                } else {
                    Text("\(number)")
                        .foregroundColor(isActive ? .white : .gray)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(isActive || isCompleted ? .primary : .secondary)
        }
    }
}

@available(iOS 15.0, *)
struct StepLine: View {
    let isActive: Bool
    
    var body: some View {
        Rectangle()
            .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
            .frame(height: 2)
    }
}

/// Grid layout payment selection
@available(iOS 15.0, *)
struct GridPaymentSelectionView: View {
    let onStepChange: (CompletelyCustomCheckoutExample.CheckoutStep) -> Void
    
    var body: some View {
        AsyncScopeView { checkoutScope, cardFormScope, paymentSelectionScope in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Select Payment Method")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Grid of payment methods
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        // Card payment option
                        PaymentOptionCard(
                            icon: "creditcard.fill",
                            title: "Credit/Debit Card",
                            description: "Visa, Mastercard, Amex",
                            color: .blue
                        ) {
                            onStepChange(.enterCardDetails)
                        }
                        
                        // Other payment options would go here
                        PaymentOptionCard(
                            icon: "applelogo",
                            title: "Apple Pay",
                            description: "Fast and secure",
                            color: .black
                        ) {
                            // Handle Apple Pay
                        }
                        
                        PaymentOptionCard(
                            icon: "p.circle.fill",
                            title: "PayPal",
                            description: "Pay with PayPal",
                            color: .blue
                        ) {
                            // Handle PayPal
                        }
                        
                        PaymentOptionCard(
                            icon: "building.columns",
                            title: "Bank Transfer",
                            description: "Direct from bank",
                            color: .green
                        ) {
                            // Handle bank transfer
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }
}

@available(iOS 15.0, *)
struct PaymentOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Card form with inline validation
@available(iOS 15.0, *)
struct InlineValidationCardForm: View {
    let onStepChange: (CompletelyCustomCheckoutExample.CheckoutStep) -> Void
    
    var body: some View {
        AsyncScopeView { checkoutScope, cardFormScope, paymentSelectionScope in
            ScrollView {
                VStack(spacing: 24) {
                    // Back button
                    HStack {
                        Button {
                            onStepChange(.selectPayment)
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Back")
                            }
                            .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Enter Card Details")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Using the NEW scope components
                        cardFormScope.PrimerCardDetails()
                        
                        // Add billing address if needed
                        Text("Billing Address")
                            .font(.headline)
                            .padding(.top)
                        
                        cardFormScope.PrimerBillingAddress()
                        
                        // Submit with custom text
                        cardFormScope.PrimerSubmitButton(text: "Pay Now")
                            .padding(.top)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }
}

/// Success screen with confetti animation
@available(iOS 15.0, *)
struct ConfettiSuccessScreen: View {
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                VStack(spacing: 16) {
                    Text("Payment Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your order has been confirmed")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Button("View Order Details") {
                    // Handle view order
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation {
                showConfetti = true
            }
        }
    }
}

/// Simple confetti animation view
@available(iOS 15.0, *)
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(confettiPieces) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: 10, height: 10)
                    .position(x: piece.x, y: piece.y)
                    .rotationEffect(.degrees(piece.rotation))
                    .animation(.linear(duration: 3), value: piece.y)
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    private func createConfetti() {
        for _ in 0..<50 {
            confettiPieces.append(ConfettiPiece())
        }
        
        // Animate falling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for i in 0..<confettiPieces.count {
                confettiPieces[i].y = UIScreen.main.bounds.height + 50
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat = CGFloat.random(in: 0...UIScreen.main.bounds.width)
    var y: CGFloat = -50
    var rotation: Double = Double.random(in: 0...360)
    var color: Color = [.red, .blue, .green, .yellow, .purple, .orange].randomElement()!
}

// swiftlint:enable file_length