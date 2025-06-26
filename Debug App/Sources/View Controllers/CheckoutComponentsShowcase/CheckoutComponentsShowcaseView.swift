//
//  CheckoutComponentsShowcaseView.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Comprehensive showcase demonstrating CheckoutComponents customization capabilities
@available(iOS 15.0, *)
struct CheckoutComponentsShowcaseView: View {
    let clientToken: String
    let settings: PrimerSettings
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: ShowcaseSection = .layouts
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("CheckoutComponents Showcase")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Explore the full power and flexibility of CheckoutComponents")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                
                // Section Picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(ShowcaseSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                ScrollView {
                    Group {
                        switch selectedSection {
                        case .layouts:
                            LayoutConfigurationsSection(clientToken: clientToken, settings: settings)
                        case .styling:
                            StylingVariationsSection(clientToken: clientToken, settings: settings)
                        case .interactive:
                            InteractiveFeaturesSection(clientToken: clientToken, settings: settings)
                        case .advanced:
                            AdvancedCustomizationSection(clientToken: clientToken, settings: settings)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .overlay(alignment: .topTrailing) {
            Button("Done") {
                dismiss()
            }
            .padding()
        }
    }
}

// MARK: - Showcase Sections

/// Layout Configurations showcase section
@available(iOS 15.0, *)
struct LayoutConfigurationsSection: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        ShowcaseSection(
            title: "Layout Configurations",
            subtitle: "Different ways to arrange CheckoutComponents"
        ) {
            VStack(spacing: 16) {
                ShowcaseDemo(
                    title: "Compact Layout",
                    description: "Horizontal fields with tight spacing"
                ) {
                    CompactCardFormDemo(clientToken: clientToken, settings: settings)
                }
                
                ShowcaseDemo(
                    title: "Expanded Layout", 
                    description: "Vertical fields with generous spacing"
                ) {
                    ExpandedCardFormDemo(clientToken: clientToken, settings: settings)
                }
                
                ShowcaseDemo(
                    title: "Inline Layout",
                    description: "Embedded seamlessly in content"
                ) {
                    InlineCardFormDemo(clientToken: clientToken, settings: settings)
                }
                
                ShowcaseDemo(
                    title: "Grid Layout",
                    description: "Card details in organized grid"
                ) {
                    GridCardFormDemo(clientToken: clientToken, settings: settings)
                }
            }
        }
    }
}

/// Styling Variations showcase section
@available(iOS 15.0, *)
struct StylingVariationsSection: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        ShowcaseSection(
            title: "Styling Variations",
            subtitle: "Various visual themes and customizations"
        ) {
            VStack(spacing: 16) {
                ShowcaseDemo(
                    title: "Corporate Theme",
                    description: "Professional blue and gray styling"
                ) {
                    CorporateThemedCardFormDemo(clientToken: clientToken, settings: settings)
                }
                
                ShowcaseDemo(
                    title: "Modern Theme",
                    description: "Clean white with subtle shadows"
                ) {
                    ModernThemedCardFormDemo(clientToken: clientToken, settings: settings)
                }
                
                ShowcaseDemo(
                    title: "Colorful Theme",
                    description: "Branded colors with gradients"
                ) {
                    ColorfulThemedCardFormDemo(clientToken: clientToken, settings: settings)
                }
                
                ShowcaseDemo(
                    title: "Dark Theme",
                    description: "Full dark mode implementation"
                ) {
                    DarkThemedCardFormDemo(clientToken: clientToken, settings: settings)
                }
            }
        }
    }
}

/// Interactive Features showcase section
@available(iOS 15.0, *)
struct InteractiveFeaturesSection: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        ShowcaseSection(
            title: "Interactive Features",
            subtitle: "Dynamic behaviors and real-time interactions"
        ) {
            VStack(spacing: 16) {
                ShowcaseDemo(
                    title: "Live State Demo",
                    description: "Real-time state updates and debugging"
                ) {
                    LiveStateCardFormDemo(clientToken: clientToken, settings: settings)
                }
                
                ShowcaseDemo(
                    title: "Validation Showcase",
                    description: "Error states and validation feedback"
                ) {
                    ValidationCardFormDemo(clientToken: clientToken, settings: settings)
                }
                
                ShowcaseDemo(
                    title: "Co-badged Cards",
                    description: "Multiple network selection demo"
                ) {
                    CoBadgedCardFormDemo(clientToken: clientToken, settings: settings)
                }
            }
        }
    }
}

/// Advanced Customization showcase section
@available(iOS 15.0, *)
struct AdvancedCustomizationSection: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        ShowcaseSection(
            title: "Advanced Customization",
            subtitle: "Complex styling and custom implementations"
        ) {
            VStack(spacing: 16) {
                ShowcaseDemo(
                    title: "PrimerModifier Chains",
                    description: "Complex styling combinations"
                ) {
                    ModifierChainsCardFormDemo(clientToken: clientToken, settings: settings)
                }
                
                ShowcaseDemo(
                    title: "Custom Screen Layout",
                    description: "Completely custom form layouts"
                ) {
                    CustomScreenCardFormDemo(clientToken: clientToken, settings: settings)
                }
                
                ShowcaseDemo(
                    title: "Animation Playground",
                    description: "Various animation styles"
                ) {
                    AnimatedCardFormDemo(clientToken: clientToken, settings: settings)
                }
            }
        }
    }
}
