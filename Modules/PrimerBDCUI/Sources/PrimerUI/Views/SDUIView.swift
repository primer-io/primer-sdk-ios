//
//  SDUIView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit
@_spi(PrimerInternal) import PrimerFoundation

@available(iOS 16.0, *) @_spi(PrimerInternal)
public struct SDUIView: View {
    @StateObject private var viewModel: SDUIViewModel
    private let onClose: (() -> Void)?
    private let titleImage: UIImage?

    public init(
        onEvent: @escaping (CodableValue) async throws -> Void,
        onClose: (() -> Void)? = nil,
        titleImage: UIImage? = nil,
        onError: ((Error) async -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: SDUIViewModel(onEvent: onEvent, onError: onError))
        self.onClose = onClose
        self.titleImage = titleImage
    }

    public var body: some View {
        Group {
            if let definition = viewModel.currentUITree {
                RoutedNavigationStack(router: viewModel.router) {
                    ContainerBodyView(uiDefinition: definition)
                        .navigationDestination(for: ContainerRouteStep.self, destination: makeDestination)
                        .toolbar(content: makeToolbar)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .environmentObject(viewModel)
            } else {
                ProgressView()
            }
        }
    }
    
    private func makeToolbar() -> some ToolbarContent {
        Group {
            makeCloseToolbar()
            makeTitleToolbar()
        }
    }

    @ToolbarContentBuilder
    private func makeCloseToolbar() -> some ToolbarContent {
        if let onClose {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }

    @ToolbarContentBuilder
    private func makeTitleToolbar() -> some ToolbarContent {
        if let titleImage {
            ToolbarItem(placement: .principal) {
                Image(uiImage: titleImage)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
    
    private func makeDestination(_ step: ContainerRouteStep) -> some View {
        switch step {
        case let .detail(definition):
            ContainerBodyView(uiDefinition: definition)
                .environmentObject(viewModel)
        }
    }

}

@available(iOS 16.0, *)
private struct RoutedNavigationStack<Content: View>: View {
    @ObservedObject var router: Router
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack(path: $router.path, root: content)
    }
}

@available(iOS 16.0, *)
private struct ContainerBodyView: View {
    let uiDefinition: UIDefinition
    
    @FocusState private var focusedFieldID: String?
    @EnvironmentObject private var viewModel: SDUIViewModel
    
    var body: some View {
        makeLayoutView(uiDefinition)
            .onChange(of: focusedFieldID) { viewModel.focusedFieldID = $0 }
            .onReceive(viewModel.$focusedFieldID) { focusedFieldID = $0 }
    }
    
    private func makeLayoutView(_ definition: UIDefinition) -> some View {
        LayoutView(focusedFieldID: $focusedFieldID, uiDefinition: definition)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
