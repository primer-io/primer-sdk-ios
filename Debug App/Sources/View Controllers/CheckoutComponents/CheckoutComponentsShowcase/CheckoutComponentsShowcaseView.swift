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
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var selectedSection: ShowcaseCategory = .layouts
    
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
                    ForEach(ShowcaseCategory.allCases, id: \.self) { section in
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
                            LayoutConfigurationsSection(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                        case .styling:
                            StylingVariationsSection(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                        case .interactive:
                            InteractiveFeaturesSection(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                        case .advanced:
                            AdvancedCustomizationSection(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
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
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
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
                    CompactCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Expanded Layout", 
                    description: "Vertical fields with generous spacing"
                ) {
                    ExpandedCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Inline Layout",
                    description: "Embedded seamlessly in content"
                ) {
                    InlineCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Grid Layout",
                    description: "Card details in organized grid"
                ) {
                    GridCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
            }
        }
    }
}

/// Styling Variations showcase section
@available(iOS 15.0, *)
struct StylingVariationsSection: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
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
                    CorporateThemedCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Modern Theme",
                    description: "Clean white with subtle shadows"
                ) {
                    ModernThemedCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Colorful Theme",
                    description: "Branded colors with gradients"
                ) {
                    ColorfulThemedCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Dark Theme",
                    description: "Full dark mode implementation"
                ) {
                    DarkThemedCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
            }
        }
    }
}

/// Interactive Features showcase section
@available(iOS 15.0, *)
struct InteractiveFeaturesSection: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
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
                    LiveStateCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Validation Showcase",
                    description: "Error states and validation feedback"
                ) {
                    ValidationCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Co-badged Cards",
                    description: "Multiple network selection demo"
                ) {
                    CoBadgedCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
            }
        }
    }
}

/// Advanced Customization showcase section
@available(iOS 15.0, *)
struct AdvancedCustomizationSection: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
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
                    ModifierChainsCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Custom Screen Layout",
                    description: "Completely custom form layouts"
                ) {
                    CustomScreenCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Animation Playground",
                    description: "Various animation styles"
                ) {
                    AnimatedCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
            }
        }
    }
}
