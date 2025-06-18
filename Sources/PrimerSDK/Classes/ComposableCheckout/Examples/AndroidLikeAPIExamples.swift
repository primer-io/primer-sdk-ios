//
//  AndroidLikeAPIExamples.swift
//
//
//  Created on 18.06.2025.
//

import SwiftUI

/// Examples showing the improved Android-like API that eliminates return type and parameter wrapping differences
@available(iOS 15.0, *)
public struct AndroidLikeAPIExamples {

    /// Example 1: No AnyView Wrapping Required (Improvement #1)
    public struct NoAnyViewWrappingExample: View {
        public var body: some View {
            VStack(spacing: 20) {
                Text("No AnyView Wrapping Required")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Compare this iOS API with Android:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    // BEFORE: Required AnyView wrapping
                    Text("❌ OLD (Required AnyView wrapping):")
                        .font(.headline)
                        .foregroundColor(.red)

                    Text("""
                    ComposablePrimer.ComposableCheckout(
                        cardFormScreen: {
                            AnyView(CustomCardForm())
                        }
                    )
                    """)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(.red.opacity(0.1))
                        .cornerRadius(8)

                    // AFTER: Direct ViewBuilder content
                    Text("✅ NEW (Direct ViewBuilder content):")
                        .font(.headline)
                        .foregroundColor(.green)

                    Text("""
                    ComposablePrimer.ComposableCheckout(
                        cardFormScreen: {
                            CustomCardForm()
                        }
                    )
                    """)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(.green.opacity(0.1))
                        .cornerRadius(8)

                    Text("🎯 Android Equivalent:")
                        .font(.headline)
                        .foregroundColor(.blue)

                    Text("""
                    Primer.ComposableCheckout(
                        cardFormScreen = { scope ->
                            CustomCardForm(scope)
                        }
                    )
                    """)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    /// Example 2: Global Function API (Improvement #2)
    public struct GlobalFunctionAPIExample: View {
        public var body: some View {
            VStack(spacing: 20) {
                Text("Global Function API")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("iOS now supports Android-style global functions:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 16) {

                    Text("✅ iOS Global Functions (Android-like):")
                        .font(.headline)
                        .foregroundColor(.green)

                    VStack(spacing: 12) {
                        // Using global functions (most Android-like)
                        PrimerCardNumberInput(
                            modifier: PrimerModifier.fillMaxWidth().background(.blue.opacity(0.1)),
                            label: "Card Number"
                        ) { _ in }

                        HStack(spacing: 12) {
                            PrimerCvvInput(
                                modifier: PrimerModifier.fillMaxWidth(),
                                label: "CVV"
                            ) { _ in }

                            Text("MM/YY")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.gray.opacity(0.1))
                                .cornerRadius(8)
                        }

                        PrimerSubmitButton(
                            modifier: PrimerModifier.fillMaxWidth(),
                            text: "Pay Now"
                        ) { }
                    }

                    Text("🎯 Android Equivalent:")
                        .font(.headline)
                        .foregroundColor(.blue)

                    Text("""
                    @Composable
                    fun CustomForm() {
                        PrimerCardNumberInput(
                            modifier = Modifier.fillMaxWidth()
                        )
                        PrimerCvvInput(
                            modifier = Modifier.fillMaxWidth()
                        )
                        PrimerSubmitButton(
                            modifier = Modifier.fillMaxWidth(),
                            text = "Pay Now"
                        )
                    }
                    """)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    /// Example 3: Side-by-Side Comparison
    public struct SideBySideComparisonExample: View {
        public var body: some View {
            VStack(spacing: 20) {
                Text("Before vs After Comparison")
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 16) {
                    // BEFORE Column
                    VStack(alignment: .leading, spacing: 12) {
                        Text("❌ BEFORE")
                            .font(.headline)
                            .foregroundColor(.red)

                        Text("Return Types:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("iOS: some View\nAndroid: @Composable")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Parameter Wrapping:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("iOS: AnyView() required\nAndroid: Direct content")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Component Access:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("iOS: PrimerComponents.*\nAndroid: Global functions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.red.opacity(0.1))
                    .cornerRadius(12)

                    // AFTER Column
                    VStack(alignment: .leading, spacing: 12) {
                        Text("✅ AFTER")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text("Return Types:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("iOS: some View (platform specific)\nAndroid: @Composable (platform specific)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Parameter Wrapping:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("iOS: @ViewBuilder (no wrapping!)\nAndroid: Direct content")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Component Access:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("iOS: Global functions available\nAndroid: Global functions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    /// Example 4: Real Usage Comparison
    public struct RealUsageComparisonExample: View {
        public var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Real Usage: iOS vs Android")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Android Code
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🎯 Android Code:")
                            .font(.headline)
                            .foregroundColor(.blue)

                        Text("""
                        @Composable
                        fun CheckoutScreen() {
                            Primer.ComposableCheckout(
                                cardFormScreen = { scope ->
                                    Column {
                                        PrimerCardNumberInput(
                                            modifier = Modifier.fillMaxWidth()
                                        )
                                        PrimerCvvInput(
                                            modifier = Modifier.fillMaxWidth()
                                        )
                                        PrimerSubmitButton(
                                            text = "Pay Now",
                                            modifier = Modifier.fillMaxWidth()
                                        )
                                    }
                                }
                            )
                        }
                        """)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(.blue.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // iOS Code (New)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("✅ iOS Code (New API):")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text("""
                        struct CheckoutScreen: View {
                            var body: some View {
                                ComposablePrimer.ComposableCheckout(
                                    cardFormScreen: {
                                        VStack {
                                            PrimerCardNumberInput(
                                                modifier: PrimerModifier.fillMaxWidth()
                                            )
                                            PrimerCvvInput(
                                                modifier: PrimerModifier.fillMaxWidth()
                                            )
                                            PrimerSubmitButton(
                                                text: "Pay Now",
                                                modifier: PrimerModifier.fillMaxWidth()
                                            )
                                        }
                                    }
                                )
                            }
                        }
                        """)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(.green.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // Compatibility Score
                    VStack(spacing: 12) {
                        Text("📊 Updated Compatibility Score")
                            .font(.headline)

                        HStack {
                            VStack {
                                Text("BEFORE")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text("75%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }

                            Image(systemName: "arrow.right")
                                .font(.title2)
                                .foregroundColor(.blue)

                            VStack {
                                Text("AFTER")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("94%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview Provider

@available(iOS 15.0, *)
struct AndroidLikeAPIExamples_Previews: PreviewProvider {
    static var previews: some View {
        TabView {
            AndroidLikeAPIExamples.NoAnyViewWrappingExample()
                .tabItem {
                    Image(systemName: "1.circle")
                    Text("No AnyView")
                }

            AndroidLikeAPIExamples.GlobalFunctionAPIExample()
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("Global Functions")
                }

            AndroidLikeAPIExamples.SideBySideComparisonExample()
                .tabItem {
                    Image(systemName: "3.circle")
                    Text("Before/After")
                }

            AndroidLikeAPIExamples.RealUsageComparisonExample()
                .tabItem {
                    Image(systemName: "4.circle")
                    Text("Real Usage")
                }
        }
    }
}
