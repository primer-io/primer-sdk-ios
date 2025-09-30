//
//  CheckoutComponentsExamplesView.swift
//  Debug App
//
//  Created by Claude on 27.6.25.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import SwiftUI
import PrimerSDK

@available(iOS 15.0, *)
struct CheckoutComponentsExamplesView: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
    init(settings: PrimerSettings, apiVersion: PrimerApiVersion, clientSession: ClientSessionRequestBody? = nil) {
        self.settings = settings
        self.apiVersion = apiVersion
        self.clientSession = clientSession
        print("🔍 [CheckoutComponentsExamplesView] Init called")
        print("🔍 [CheckoutComponentsExamplesView] Settings: \(settings)")
        print("🔍 [CheckoutComponentsExamplesView] API Version: \(apiVersion)")
        print("🔍 [CheckoutComponentsExamplesView] ClientSession: \(clientSession != nil ? "provided" : "nil")")
        if let session = clientSession {
            print("🔍 [CheckoutComponentsExamplesView] Surcharge settings passed through: \(session.paymentMethod?.options?.PAYMENT_CARD?.networks != nil)")
        }
    }
    
    var body: some View {
        let _ = print("🔍 [CheckoutComponentsExamplesView] body called")
        let _ = print("🔍 [CheckoutComponentsExamplesView] Categories: \(ExampleCategory.allCases.map { $0.rawValue })")
        
        List {
            ForEach(ExampleCategory.allCases, id: \.self) { category in
                NavigationLink(
                    destination: CategoryExamplesView(
                        category: category,
                        settings: settings,
                        apiVersion: apiVersion,
                        clientSession: clientSession
                    )
                ) {
                    CategoryRow(category: category)
                }
            }
        }
    }
}

// MARK: - Category Row View

@available(iOS 15.0, *)
struct CategoryRow: View {
    let category: ExampleCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(category.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(category.examples.count) examples")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Examples View

@available(iOS 15.0, *)
struct CategoryExamplesView: View {
    let category: ExampleCategory
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
    @State private var presentedExample: ExampleConfig?
    
    var body: some View {
        List {
            ForEach(category.examples) { example in
                ExampleRow(
                    example: example,
                    onTap: { 
                        print("🔍 [CategoryExamplesView] Example tapped: \(example.name)")
                        presentedExample = example
                        print("🔍 [CategoryExamplesView] presentedExample set to: \(presentedExample?.name ?? "nil")")
                    }
                )
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $presentedExample) { example in
            CheckoutExampleView(
                example: example, 
                settings: settings,
                apiVersion: apiVersion,
                clientSession: clientSession
            )
            .onAppear {
                print("🔍 [CategoryExamplesView] Sheet presenting for: \(example.name)")
                print("🔍 [CategoryExamplesView] CheckoutExampleView appeared for: \(example.name)")
            }
        }
    }
}

// MARK: - Example Row View

@available(iOS 15.0, *)
struct ExampleRow: View {
    let example: ExampleConfig
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(example.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(example.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Payment Methods:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(example.paymentMethods.joined(separator: ", "))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
                
                if let customization = example.customization {
                    HStack {
                        Text("Style:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(String(describing: customization))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
