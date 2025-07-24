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
    @State private var selectedSection: ShowcaseCategory = .architecture
    
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
                        case .architecture:
                            ArchitectureSection(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                        case .styling:
                            StylingVariationsSection(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                        case .layouts:
                            LayoutsSection(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                        case .interactive:
                            InteractiveSection(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
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

/// Architecture patterns showcase section
@available(iOS 15.0, *)
struct ArchitectureSection: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
    var body: some View {
        ShowcaseSection(
            title: "Architecture Patterns",
            subtitle: "Component composition and structure variations"
        ) {
            VStack(spacing: 16) {
                ShowcaseDemo(
                    title: "Step-by-Step Navigation",
                    description: "Single input field with Previous/Next controls"
                ) {
                    SingleInputFieldDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Mixed Components",
                    description: "Combining default and custom styled fields"
                ) {
                    MixedComponentsDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
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
                    title: "Single Field Customisation",
                    description: "Customize only cardholder name field"
                ) {
                    SingleFieldCustomisationDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
            }
        }
    }
}

/// Layout variations showcase section
@available(iOS 15.0, *)
struct LayoutsSection: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
    var body: some View {
        ShowcaseSection(
            title: "Layout Variations",
            subtitle: "Different ways to arrange form fields"
        ) {
            VStack(spacing: 16) {
                ShowcaseDemo(
                    title: "Dynamic Layouts",
                    description: "Switch between vertical, horizontal, grid, and compact layouts"
                ) {
                    CustomCardFormLayoutDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
            }
        }
    }
}

/// Interactive features showcase section
@available(iOS 15.0, *)
struct InteractiveSection: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
    var body: some View {
        ShowcaseSection(
            title: "Interactive Features",
            subtitle: "Runtime behavior and conditional customization"
        ) {
            VStack(spacing: 16) {
                ShowcaseDemo(
                    title: "Property Reassignment",
                    description: "Change component properties dynamically at runtime"
                ) {
                    PropertyReassignmentDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
                
                ShowcaseDemo(
                    title: "Conditional Customization",
                    description: "Components adapt based on card type and validation state"
                ) {
                    RuntimeCustomizationDemo(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
                }
            }
        }
    }
}
