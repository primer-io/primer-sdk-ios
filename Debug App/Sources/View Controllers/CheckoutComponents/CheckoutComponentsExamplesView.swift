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
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ExampleCategory.allCases, id: \.self) { category in
                    NavigationLink(
                        destination: CategoryExamplesView(
                            category: category,
                            settings: settings,
                            apiVersion: apiVersion
                        )
                    ) {
                        CategoryRow(category: category)
                    }
                }
            }
            .navigationTitle("CheckoutComponents Examples")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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
    
    @State private var showingCheckout = false
    @State private var selectedExample: ExampleConfig?
    
    var body: some View {
        List {
            ForEach(category.examples) { example in
                ExampleRow(
                    example: example,
                    onTap: { 
                        selectedExample = example
                        showingCheckout = true 
                    }
                )
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCheckout) {
            if let example = selectedExample {
                CheckoutExampleView(
                    example: example, 
                    settings: settings,
                    apiVersion: apiVersion
                )
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