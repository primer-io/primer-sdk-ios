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
    @State private var selectedSection: ShowcaseCategory = .styling
    
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
                        case .styling:
                            StylingVariationsSection(settings: settings, apiVersion: apiVersion, clientSession: clientSession)
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
