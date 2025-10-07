//
//  CheckoutComponentsShowcaseView.swift
//  Debug App
//
//  Created on 26.6.25.
//
import SwiftUI
import PrimerSDK

/// Comprehensive showcase demonstrating CheckoutComponents customization capabilities
@available(iOS 15.0, *)
struct CheckoutComponentsShowcaseView: View {
    private let settings: PrimerSettings
    private let apiVersion: PrimerApiVersion
    private let clientSession: ClientSessionRequestBody?
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var selectedSection: ShowcaseCategory = .architecture
    
    var body: some View {
        makeNavigationView()
            .overlay(alignment: .topTrailing) {
                Button("Done") {
                    dismiss()
                }
                .padding()
            }
    }
    
    private func makeNavigationView() -> some View {
        NavigationView {
            VStack(spacing: 0) {
                makeHeader()
                makeSectionPicker()
                makeContent()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func makeHeader() -> some View {
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
    }
    
    private func makeSectionPicker() -> some View {
        Picker("Section", selection: $selectedSection) {
            ForEach(ShowcaseCategory.allCases, id: \.self) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private func makeContent() -> some View {
        ScrollView {
            switch selectedSection {
            case .architecture:
                makeArchitectureDemo()
            case .styling:
                makeStylingDemo()
            case .layouts:
                makeLayoutsDemo()
            case .interactive:
                makeInteractiveDemo()
            }
        }
    }
}

// MARK: - Architecture Demo
@available(iOS 15.0, *)
private extension CheckoutComponentsShowcaseView {
    func makeArchitectureDemo() -> some View {
        ShowcaseSectionView(
            title: "Architecture Patterns",
            subtitle: "Component composition and structure variations"
        ) {
            ShowcaseDemo(
                title: "Step-by-Step Navigation",
                description: "Single input field with Previous/Next controls",
                content: makeSingleInputDemo
            )
            
            ShowcaseDemo(
                title: "Mixed Components",
                description: "Combining default and custom styled fields",
                content: makeMixedComponentsDemo
            )
        }
    }
    
    func makeSingleInputDemo() -> some View {
        SingleInputFieldDemo(
            settings: settings,
            apiVersion: apiVersion,
            clientSession: clientSession
        )
    }
    
    func makeMixedComponentsDemo() -> some View {
        MixedComponentsDemo(
            settings: settings,
            apiVersion: apiVersion,
            clientSession: clientSession
        )
    }
}

// MARK: - Styling Demo
@available(iOS 15.0, *)
private extension CheckoutComponentsShowcaseView {
    func makeStylingDemo() -> some View {
        ShowcaseSectionView(
            title: "Styling Variations",
            subtitle: "Various visual themes and customizations"
        ) {
            ShowcaseDemo(
                title: "Single Field Customisation",
                description: "Customize only cardholder name field",
                content: makeSingleFieldCustomisationDemo
            )
        }
    }
    
    func makeSingleFieldCustomisationDemo() -> some View {
        SingleFieldCustomisationDemo(
            settings: settings,
            apiVersion: apiVersion,
            clientSession: clientSession
        )
    }
}

// MARK: - Layouts Demo
@available(iOS 15.0, *)
private extension CheckoutComponentsShowcaseView {
    func makeLayoutsDemo() -> some View {
        ShowcaseSectionView(
            title: "Layout Variations",
            subtitle: "Different ways to arrange form fields"
        ) {
            ShowcaseDemo(
                title: "Dynamic Layouts",
                description: "Switch between vertical, horizontal, grid, and compact layouts",
                content: makeCustomCardFormLayoutDemo
            )
            
            ShowcaseDemo(
                title: "Custom Payment Selection Screen",
                description: "Complete UI customization with gradient backgrounds and animations",
                content: makeCustomScreenPaymentSelectionDemo
            )
        }
    }
    
    func makeCustomCardFormLayoutDemo() -> some View {
        CustomCardFormLayoutDemo(
            settings: settings,
            apiVersion: apiVersion,
            clientSession: clientSession
        )
    }
    
    func makeCustomScreenPaymentSelectionDemo() -> some View {
        CustomScreenPaymentSelectionDemo(
            settings: settings,
            apiVersion: apiVersion,
            clientSession: clientSession
        )
    }
}

// MARK: - Interactive Demo
@available(iOS 15.0, *)
private extension CheckoutComponentsShowcaseView {
    func makeInteractiveDemo() -> some View {
        ShowcaseSectionView(
            title: "Interactive Features",
            subtitle: "Runtime behavior and conditional customization"
        ) {
            ShowcaseDemo(
                title: "Property Reassignment",
                description: "Change component properties dynamically at runtime",
                content: makePropertyReassignmentDemo
            )
            
            ShowcaseDemo(
                title: "Conditional Customization",
                description: "Components adapt based on card type and validation state",
                content: makeRuntimeCustomizationDemo
            )
        }
    }
    
    func makePropertyReassignmentDemo() -> some View {
        PropertyReassignmentDemo(
            settings: settings,
            apiVersion: apiVersion,
            clientSession: clientSession
        )
    }
    
    func makeRuntimeCustomizationDemo() -> some View {
        RuntimeCustomizationDemo(
            settings: settings,
            apiVersion: apiVersion,
            clientSession: clientSession
        )
    }
}

// MARK: - ShowcaseSectionView

/// A reusable section view container for showcase content
@available(iOS 15.0, *)
private struct ShowcaseSectionView<Content: View>: View {
    fileprivate let title: String
    fileprivate let subtitle: String
    fileprivate let content: () -> Content

    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        ShowcaseSection(title: title, subtitle: subtitle) {
            VStack(spacing: 16, content: content)
        }
    }
}
