//
//  AndroidCompatibilityExamples.swift
//
//
//  Created on 18.06.2025.
//

import SwiftUI
import Combine

/// Examples demonstrating how the iOS ComposableCheckout API now matches Android patterns
@available(iOS 15.0, *)
public struct AndroidCompatibilityExamples: LogReporter {

    /// Example 1: Direct Component Access (matches Android's top-level composables)
    public struct DirectComponentUsageExample: View {
        public var body: some View {
            VStack(spacing: 16) {
                Text("Direct Component Usage")
                    .font(.title2)
                    .fontWeight(.bold)

                // Using PrimerComponents directly (similar to Android)
                PrimerComponents.PrimerCardNumberInput(
                    modifier: PrimerModifier.fillMaxWidth()
                        .padding(.horizontal, 16)
                        .background(.gray.opacity(0.1))
                        .cornerRadius(8),
                    label: "Card Number",
                    placeholder: "1234 5678 9012 3456"
                ) { cardNumber in
                    logger.debug(message: "Card number changed: \(cardNumber)")
                }

                HStack(spacing: 12) {
                    PrimerComponents.PrimerExpiryDateInput(
                        modifier: PrimerModifier.fillMaxWidth(),
                        label: "Expiry",
                        placeholder: "MM/YY"
                    ) { expiry in
                        logger.debug(message: "Expiry changed: \(expiry)")
                    }

                    PrimerComponents.PrimerCvvInput(
                        modifier: PrimerModifier.fillMaxWidth(),
                        label: "CVV",
                        placeholder: "123"
                    ) { cvv in
                        logger.debug(message: "CVV changed: \(cvv)")
                    }
                }

                PrimerComponents.PrimerSubmitButton(
                    modifier: PrimerModifier.fillMaxWidth()
                        .padding(.horizontal, 16)
                        .height(50),
                    text: "Pay Now",
                    enabled: true
                ) {
                    logger.debug(message: "Submit button tapped")
                }
            }
            .padding()
        }
    }

    /// Example 2: Scope-Based Usage with Modifiers (enhanced version of existing pattern)
    public struct ScopeBasedUsageExample: View {
        @StateObject private var mockScope = MockCardFormScope()

        public var body: some View {
            VStack(spacing: 16) {
                Text("Scope-Based Usage with Modifiers")
                    .font(.title2)
                    .fontWeight(.bold)

                // Using scope functions with modifier system
                mockScope.PrimerCardNumberInput(
                    modifier: PrimerModifier.fillMaxWidth()
                        .background(.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 8),
                    label: "Card Number",
                    placeholder: "Enter your card number"
                )

                HStack(spacing: 12) {
                    mockScope.PrimerExpiryDateInput(
                        modifier: PrimerModifier.fillMaxWidth()
                            .background(.green.opacity(0.1))
                            .cornerRadius(8)
                    )

                    mockScope.PrimerCvvInput(
                        modifier: PrimerModifier.fillMaxWidth()
                            .background(.orange.opacity(0.1))
                            .cornerRadius(8)
                    )
                }

                mockScope.PrimerSubmitButton(
                    modifier: PrimerModifier.fillMaxWidth()
                        .height(50)
                        .background(.purple)
                        .cornerRadius(12)
                        .shadow(radius: 4),
                    text: "Complete Payment"
                )
            }
            .padding()
        }
    }

    /// Example 3: Android-Style Modifier Chains
    public struct ModifierChainingExample: View {
        public var body: some View {
            VStack(spacing: 20) {
                Text("Android-Style Modifier Chaining")
                    .font(.title2)
                    .fontWeight(.bold)

                // Demonstrating chainable modifiers (like Android's Modifier.* pattern)
                PrimerComponents.PrimerCardNumberInput(
                    modifier: PrimerModifier
                        .fillMaxWidth()
                        .padding(.all, 16)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(12)
                        .border(.blue, width: 1)
                        .shadow(color: .gray, radius: 2, x: 0, y: 1),
                    label: "Card Number with Styled Modifier"
                )

                PrimerComponents.PrimerSubmitButton(
                    modifier: PrimerModifier
                        .fillMaxWidth()
                        .height(60)
                        .backgroundGradient(
                            Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4),
                    text: "Stylized Pay Button",
                    enabled: true
                ) {
                    // Handle payment
                }
            }
            .padding()
        }
    }

    /// Example 4: Composite Components (matching Android patterns)
    public struct CompositeComponentExample: View {
        public var body: some View {
            VStack(spacing: 24) {
                Text("Composite Components")
                    .font(.title2)
                    .fontWeight(.bold)

                // Using composite components (like Android's composite functions)
                PrimerComponents.PrimerCardDetails(
                    modifier: PrimerModifier
                        .fillMaxWidth()
                        .padding(.all, 16)
                        .background(.gray.opacity(0.05))
                        .cornerRadius(16)
                        .border(.gray.opacity(0.3), width: 1),
                    onCardNumberChange: { _ in },
                    onCvvChange: { _ in },
                    onExpiryDateChange: { _ in },
                    onCardholderNameChange: { _ in }
                )

                PrimerComponents.PrimerBillingAddress(
                    modifier: PrimerModifier
                        .fillMaxWidth()
                        .padding(.all, 16)
                        .background(.blue.opacity(0.05))
                        .cornerRadius(16)
                        .border(.blue.opacity(0.3), width: 1),
                    onAddressChange: { address in
                        logger.debug(message: "Address changed: \(address)")
                    }
                )
            }
            .padding()
        }
    }

    /// Example 5: Migration from Android Code Style
    public struct AndroidMigrationExample: View {
        public var body: some View {
            VStack(spacing: 16) {
                Text("Android Migration Pattern")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("This structure closely matches Android Compose syntax")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // This structure now closely matches what Android developers expect:
                /*
                 Android equivalent:

                 @Composable
                 fun CheckoutScreen() {
                 Column(
                 modifier = Modifier.fillMaxSize().padding(16.dp),
                 verticalArrangement = Arrangement.spacedBy(16.dp)
                 ) {
                 PrimerCardNumberInput(
                 modifier = Modifier.fillMaxWidth()
                 )

                 Row(
                 modifier = Modifier.fillMaxWidth(),
                 horizontalArrangement = Arrangement.spacedBy(12.dp)
                 ) {
                 PrimerExpiryDateInput(modifier = Modifier.weight(1f))
                 PrimerCvvInput(modifier = Modifier.weight(1f))
                 }

                 PrimerSubmitButton(
                 modifier = Modifier.fillMaxWidth().height(50.dp),
                 text = "Pay Now"
                 )
                 }
                 }
                 */

                // iOS equivalent using the new API:
                VStack(spacing: 16) {
                    PrimerComponents.PrimerCardNumberInput(
                        modifier: PrimerModifier.fillMaxWidth()
                    )

                    HStack(spacing: 12) {
                        PrimerComponents.PrimerExpiryDateInput(
                            modifier: PrimerModifier.fillMaxWidth()
                        )
                        PrimerComponents.PrimerCvvInput(
                            modifier: PrimerModifier.fillMaxWidth()
                        )
                    }

                    PrimerComponents.PrimerSubmitButton(
                        modifier: PrimerModifier.fillMaxWidth().height(50),
                        text: "Pay Now"
                    )
                }
            }
            .padding()
        }
    }

    /// Example 6: Static Factory Methods (matches Android's Modifier.* pattern)
    public struct StaticFactoryExample: View {
        public var body: some View {
            VStack(spacing: 16) {
                Text("Static Factory Methods")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Using static factory methods like Android's Modifier.fillMaxWidth()")
                    .font(.caption)
                    .foregroundColor(.secondary)

                PrimerComponents.PrimerCardNumberInput(
                    // Using static factory methods (matches Android exactly)
                    modifier: PrimerModifier.fillMaxWidth()
                        .then(PrimerModifier.padding(.all, 16))
                        .then(PrimerModifier.background(.blue.opacity(0.1)))
                        .then(PrimerModifier().cornerRadius(8))
                )

                PrimerComponents.PrimerSubmitButton(
                    modifier: PrimerModifier.fillMaxSize()
                        .then(PrimerModifier.background(.blue))
                        .then(PrimerModifier().cornerRadius(12)),
                    text: "Static Factory Example"
                )
            }
            .padding()
        }
    }
}

// MARK: - Helper Extensions

@available(iOS 15.0, *)
private extension PrimerModifier {
    /// Combines two modifiers (similar to Android's then() function)
    func then(_ other: PrimerModifier) -> PrimerModifier {
        var combined = self
        combined.modifiers.append(contentsOf: other.modifiers)
        return combined
    }
}

// MARK: - Mock Implementation for Examples

@available(iOS 15.0, *)
private class MockCardFormScope: CardFormScope, ObservableObject, LogReporter {
    @Published private var _state = CardFormState.initial

    var state: AnyPublisher<CardFormState, Never> {
        $_state.eraseToAnyPublisher()
    }

    func updateCardNumber(_ cardNumber: String) {
        logger.debug(message: "Mock: Card number updated to \(cardNumber)")
    }

    func updateCvv(_ cvv: String) {
        logger.debug(message: "Mock: CVV updated to \(cvv)")
    }

    func updateExpiryDate(_ expiryDate: String) {
        logger.debug(message: "Mock: Expiry date updated to \(expiryDate)")
    }

    func updateCardholderName(_ cardholderName: String) {
        logger.debug(message: "Mock: Cardholder name updated to \(cardholderName)")
    }

    func updatePostalCode(_ postalCode: String) {}
    func updateCountryCode(_ countryCode: String) {}
    func updateCity(_ city: String) {}
    func updateState(_ state: String) {}
    func updateAddressLine1(_ addressLine1: String) {}
    func updateAddressLine2(_ addressLine2: String) {}
    func updatePhoneNumber(_ phoneNumber: String) {}
    func updateFirstName(_ firstName: String) {}
    func updateLastName(_ lastName: String) {}
    func updateRetailOutlet(_ retailOutlet: String) {}
    func updateOtpCode(_ otpCode: String) {}

    func submit() {
        logger.debug(message: "Mock: Form submitted")
    }
}

// MARK: - Preview Provider

@available(iOS 15.0, *)
struct AndroidCompatibilityExamples_Previews: PreviewProvider {
    static var previews: some View {
        TabView {
            AndroidCompatibilityExamples.DirectComponentUsageExample()
                .tabItem {
                    Image(systemName: "1.circle")
                    Text("Direct")
                }

            AndroidCompatibilityExamples.ScopeBasedUsageExample()
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("Scope")
                }

            AndroidCompatibilityExamples.ModifierChainingExample()
                .tabItem {
                    Image(systemName: "3.circle")
                    Text("Modifiers")
                }

            AndroidCompatibilityExamples.CompositeComponentExample()
                .tabItem {
                    Image(systemName: "4.circle")
                    Text("Composite")
                }

            AndroidCompatibilityExamples.AndroidMigrationExample()
                .tabItem {
                    Image(systemName: "5.circle")
                    Text("Migration")
                }
        }
    }
}
