//
//  CustomScreenCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Custom screen layout demo with completely custom form layouts
@available(iOS 15.0, *)
struct CustomScreenCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        VStack {
            Text("Custom Screen Demo")
                .font(.headline)
                .padding()
            
            Text("Completely custom form layouts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Button("Show Custom Screen Checkout") {
                presentCheckout(title: "CustomScreenCardFormDemo")
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 200)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func presentCheckout(title: String) {
        // Find the current view controller to present from
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = findTopViewController(from: window.rootViewController) else {
            print("❌ [\(title)] Could not find view controller to present from")
            return
        }
        
        print("🔍 [\(title)] Button tapped - presenting CheckoutComponents")

        // Present using CheckoutComponentsPrimer with custom screen layout content
        CheckoutComponentsPrimer.presentCheckout(
            with: clientToken,
            from: rootViewController,
            customContent: { checkoutScope in
                checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                    guard let cardScope = scope as? any PrimerCardFormScope else {
                        return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                    }
                    return AnyView(
                        GeometryReader { geometry in
                            ScrollView {
                                VStack(spacing: 24) {
                                    // Custom header with split design
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("💳")
                                                .font(.largeTitle)
                                            Text("Custom")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                            Text("Payment")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Secure")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                            Text("256-bit")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal)
                                    
                                    // Split-screen layout
                                    if geometry.size.width > 400 {
                                        // Wide layout - side by side
                                        HStack(spacing: 20) {
                                            // Left column
                                            VStack(spacing: 16) {
                                                if let cardNumberInput = cardScope.cardNumberInput {
                                                    cardNumberInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 14)
                                                        .background(.white)
                                                        .cornerRadius(10)
                                                        .border(.gray.opacity(0.3), width: 1)
                                                    )
                                                }
                                                
                                                if let cardholderNameInput = cardScope.cardholderNameInput {
                                                    cardholderNameInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 14)
                                                        .background(.white)
                                                        .cornerRadius(10)
                                                        .border(.gray.opacity(0.3), width: 1)
                                                    )
                                                }
                                            }
                                            
                                            // Right column
                                            VStack(spacing: 16) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    expiryDateInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 14)
                                                        .background(.white)
                                                        .cornerRadius(10)
                                                        .border(.gray.opacity(0.3), width: 1)
                                                    )
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    cvvInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 14)
                                                        .background(.white)
                                                        .cornerRadius(10)
                                                        .border(.gray.opacity(0.3), width: 1)
                                                    )
                                                }
                                            }
                                        }
                                    } else {
                                        // Narrow layout - stacked
                                        VStack(spacing: 16) {
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                cardNumberInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(50)
                                                    .padding(.horizontal, 14)
                                                    .background(.white)
                                                    .cornerRadius(10)
                                                    .border(.gray.opacity(0.3), width: 1)
                                                )
                                            }
                                            
                                            HStack(spacing: 12) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    expiryDateInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 14)
                                                        .background(.white)
                                                        .cornerRadius(10)
                                                        .border(.gray.opacity(0.3), width: 1)
                                                    )
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    cvvInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 14)
                                                        .background(.white)
                                                        .cornerRadius(10)
                                                        .border(.gray.opacity(0.3), width: 1)
                                                    )
                                                }
                                            }
                                            
                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                cardholderNameInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(50)
                                                    .padding(.horizontal, 14)
                                                    .background(.white)
                                                    .cornerRadius(10)
                                                    .border(.gray.opacity(0.3), width: 1)
                                                )
                                            }
                                        }
                                    }
                                    
                                    // Custom footer
                                    HStack {
                                        Image(systemName: "lock.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Custom secured checkout")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("Adaptive layout")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal)
                                }
                                .padding()
                            }
                        }
                        .background(LinearGradient(
                            gradient: Gradient(colors: [.gray.opacity(0.02), .blue.opacity(0.02)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    )
                }
                return AnyView(EmptyView())
            },
            completion: {
                print("✅ [\(title)] CheckoutComponents presentation completed")
            }
        )
        
        print("✅ [\(title)] CheckoutComponents presentation initiated")
    }

    private func findTopViewController(from rootViewController: UIViewController?) -> UIViewController? {
        if let presented = rootViewController?.presentedViewController {
            return findTopViewController(from: presented)
        }
        
        if let navigationController = rootViewController as? UINavigationController {
            return findTopViewController(from: navigationController.visibleViewController)
        }
        
        if let tabBarController = rootViewController as? UITabBarController {
            return findTopViewController(from: tabBarController.selectedViewController)
        }
        
        return rootViewController
    }
}
