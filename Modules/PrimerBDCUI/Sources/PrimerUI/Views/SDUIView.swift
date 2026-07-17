//
//  SDUIView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 16.0, *)
public struct SDUIView: View {
    @StateObject private var viewModel: SDUIViewModel
    @StateObject private var router: Router
    
    public init() {
        let viewModel = SDUIViewModel()
        _viewModel = StateObject(wrappedValue: viewModel)
        _router = StateObject(wrappedValue: viewModel.router)
    }

    public var body: some View {
        Group {
            if let definition = viewModel.currentUITree {
                NavigationStack(path: $router.path) {
                    ContainerBodyView(uiDefinition: definition, screenID: "changeme")
                        .navigationDestination(for: ContainerRouteStep.self, destination: makeDestination)
                }
                .environmentObject(viewModel)
            } else {
                ProgressView()
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private func makeDestination(_ step: ContainerRouteStep) -> some View {
        switch step {
        case let .detail(definition, id):
            ContainerBodyView(uiDefinition: definition, screenID: id)
                .environmentObject(viewModel)
        }
    }

}

@available(iOS 16.0, *)
private struct ContainerBodyView: View {
    let uiDefinition: UIDefinition
    let screenID: String
    
    @FocusState private var focusedFieldID: String?
    @EnvironmentObject private var viewModel: SDUIViewModel
    
    var body: some View {
        makeLayoutView(uiDefinition)
            .onChange(of: focusedFieldID) { viewModel.focusedFieldID = $0 }
            .onReceive(viewModel.$focusedFieldID) { focusedFieldID = $0 }
    }
    
    private func makeLayoutView(_ definition: UIDefinition) -> some View {
        LayoutView(focusedFieldID: $focusedFieldID, uiDefinition: definition, screenID: screenID)
            .padding()
    }
}
