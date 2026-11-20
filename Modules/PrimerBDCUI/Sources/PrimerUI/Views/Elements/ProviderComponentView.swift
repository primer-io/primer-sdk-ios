//
//  ProviderComponentView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct ProviderComponentView: UIViewRepresentable {
    @EnvironmentObject private var viewModel: SDUIViewModel
    let type: String
    let id: String?
    let props: CodableValue?

    func makeUIView(context: Context) -> UIView {
        let onChange: SDUIComponentRegistry.OnChange = { [weak viewModel] id, value in
            viewModel?.applyEvent(.input(id: id, value: value, type: .onChange))
        }
        let onEvent: SDUIComponentRegistry.OnEvent = { [weak viewModel, id] type, data in
            viewModel?.applyEvent(.provider(type: type, id: id, data: data))
        }
        return SDUIComponentRegistry.shared.view(for: type, id: id, props: props, onChange: onChange, onEvent: onEvent) ?? UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        let height = uiView.intrinsicContentSize.height
        guard !height.isZero else { return nil }
        return CGSize(width: proposal.width ?? uiView.intrinsicContentSize.width, height: height)
    }
}
