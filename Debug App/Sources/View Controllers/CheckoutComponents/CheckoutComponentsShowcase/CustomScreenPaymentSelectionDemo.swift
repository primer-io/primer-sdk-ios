//
//  CustomScreenPaymentSelectionDemo.swift
//  Primer.io Debug App
//
//  Shows how to completely customize the PaymentMethodSelection screen UI
//

import SwiftUI
import PrimerSDK

@available(iOS 15.0, *)
struct CustomScreenPaymentSelectionDemo: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
    @State private var showingCheckout = false
    @State private var checkoutResult: String = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var clientToken: String?
    @State private var isDismissed = false
    
    var body: some View {
        ShowcaseDemo(
            title: "Custom Payment Selection Screen",
            description: "Complete UI customization with custom backgrounds, buttons, and layouts"
        ) {
            if isDismissed {
                dismissedStateView
            } else if isLoading {
                loadingStateView
            } else if let error = error {
                errorStateView(error)
            } else if let clientToken = clientToken {
                checkoutView(clientToken: clientToken)
            } else {
                initialStateView
            }
        }
    }
    
    private var initialStateView: some View {
        VStack(spacing: 20) {
            Text("This demo shows how to completely replace the default payment method selection screen with a custom design including:")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Custom gradient background", systemImage: "paintbrush.fill")
                Label("Floating card design", systemImage: "rectangle.3.group.fill")
                Label("Custom header and buttons", systemImage: "button.programmable")
                Label("Animated interactions", systemImage: "wand.and.rays")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button("Show Custom Payment Selection") {
                createSession()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var loadingStateView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Creating session...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
    
    private var dismissedStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            Text("Demo completed!")
                .font(.headline)
        }
    }
    
    private func errorStateView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            Text("Error")
                .font(.headline)
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                self.error = nil
                createSession()
            }
        }
    }
    
    private func checkoutView(clientToken: String) -> some View {
        VStack(spacing: 20) {
            Text("Session created! Tap below to launch checkout with custom payment selection screen.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Launch Custom Checkout") {
                showingCheckout = true
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showingCheckout) {
            PrimerCheckout(
                clientToken: clientToken,
                primerSettings: settings,
                scope: { checkoutScope in
                // Customize the payment method selection screen entirely
                checkoutScope.paymentMethodSelection.screen = {
                    AnyView(CustomPaymentSelectionScreen(scope: checkoutScope.paymentMethodSelection))
                }
                
                // Also customize category headers  
                checkoutScope.paymentMethodSelection.categoryHeader = { category in
                    AnyView(
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(category)
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .cornerRadius(8)
                        )
                        .padding(.horizontal)
                    )
                }
                
                // Custom empty state
                checkoutScope.paymentMethodSelection.emptyStateView = {
                    AnyView(
                        VStack(spacing: 20) {
                            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                                .font(.system(size: 60))
                                .foregroundColor(.purple)
                            
                            Text("No Payment Methods")
                                .font(.title2)
                                .bold()
                            
                            Text("Please contact support")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    )
                }
            },
                onCompletion: {
                    showingCheckout = false
                    checkoutResult = "✅ Payment completed!"
                    isDismissed = true
                }
            )
        }
    }
    
    private func createSession() {
        guard let clientSession = clientSession else {
            error = "Client session configuration is missing"
            return
        }

        isLoading = true
        error = nil

        let sessionBody = ClientSessionRequestBody(
            customerId: clientSession.customerId,
            orderId: clientSession.orderId ?? "custom-payment-selection-demo-\(UUID().uuidString)",
            currencyCode: clientSession.currencyCode,
            amount: clientSession.amount,
            metadata: clientSession.metadata,
            customer: clientSession.customer,
            order: clientSession.order,
            paymentMethod: clientSession.paymentMethod
        )

        Task {
            do {
                self.clientToken = try await NetworkingUtils.requestClientSession(
                    body: sessionBody,
                    apiVersion: apiVersion
                )
                self.isLoading = false
            } catch {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Custom Payment Selection Screen

@available(iOS 15.0, *)
private struct CustomPaymentSelectionScreen: View {
    let scope: PrimerPaymentMethodSelectionScope
    
    init(scope: PrimerPaymentMethodSelectionScope) {
        self.scope = scope
    }
    
    @State private var selectionState = PrimerPaymentMethodSelectionState()
    @State private var selectedMethod: PrimerComposablePaymentMethod?
    @State private var animateCards = false
    
    var body: some View {
        ZStack {
            // Custom gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.1, blue: 0.4),
                    Color(red: 0.3, green: 0.2, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background shapes
            GeometryReader { geometry in
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.3),
                                    Color.blue.opacity(0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                        .offset(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 10...20))
                                .repeatForever(autoreverses: true),
                            value: animateCards
                        )
                }
            }
            
            VStack(spacing: 0) {
                // Custom header
                customHeader
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Amount display
                        amountCard
                        
                        // Payment methods
                        paymentMethodsSection
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            observeState()
            withAnimation {
                animateCards = true
            }
        }
    }
    
    private var customHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose Payment")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                
                Text("Select your preferred method")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                scope.onCancel()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .blur(radius: 20)
        )
    }
    
    private var amountCard: some View {
        // For demo purposes, using hardcoded amount since AppState is internal
        let formattedAmount = "$99.00"
        
        return VStack(spacing: 8) {
            Text("Total Amount")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(formattedAmount)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private var paymentMethodsSection: some View {
        VStack(spacing: 16) {
            if selectionState.paymentMethods.isEmpty {
                emptyState
            } else {
                ForEach(selectionState.paymentMethods, id: \.id) { method in
                    customPaymentMethodCard(method)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No payment methods available")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private func customPaymentMethodCard(_ method: PrimerComposablePaymentMethod) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                selectedMethod = method
            }
            
            // Delay to show selection animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                scope.onPaymentMethodSelected(paymentMethod: method)
            }
        }) {
            HStack(spacing: 16) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    if let icon = method.icon {
                        Image(uiImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                    } else {
                        Image(systemName: iconForPaymentMethod(method))
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let surcharge = method.formattedSurcharge {
                        Text(surcharge)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        selectedMethod?.id == method.id
                        ? LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                selectedMethod?.id == method.id
                                ? Color.white.opacity(0.5)
                                : Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(selectedMethod?.id == method.id ? 1.05 : 1.0)
            .shadow(
                color: selectedMethod?.id == method.id
                    ? Color.purple.opacity(0.5)
                    : Color.black.opacity(0.2),
                radius: selectedMethod?.id == method.id ? 20 : 10,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForPaymentMethod(_ method: PrimerComposablePaymentMethod) -> String {
        switch method.type {
        case "PAYMENT_CARD":
            return "creditcard.fill"
        case "PAYPAL":
            return "p.circle.fill"
        case "APPLE_PAY":
            return "applelogo"
        case "GOOGLE_PAY":
            return "g.circle.fill"
        default:
            return "dollarsign.circle.fill"
        }
    }
    
    private func observeState() {
        Task {
            for await state in scope.state {
                await MainActor.run {
                    self.selectionState = state
                }
            }
        }
    }
}
