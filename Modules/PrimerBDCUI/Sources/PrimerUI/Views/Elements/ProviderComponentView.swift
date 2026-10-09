//
//  ProviderComponentView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit
@_spi(PrimerInternal) import PrimerFoundation

@available(iOS 16.0, *)
struct ProviderComponentView: UIViewRepresentable {
    @EnvironmentObject private var viewModel: SDUIViewModel
    let type: String
    let props: CodableValue?

    func makeUIView(context: Context) -> UIView {
        let onChange: SDUIComponentRegistry.OnChange = { [weak viewModel] id, value in
            viewModel?.applyEvent(.input(id: id, value: value, type: .onChange))
        }
        return SDUIComponentRegistry.shared.view(for: type, props: props, onChange: onChange) ?? UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        let height = uiView.intrinsicContentSize.height
        guard !height.isZero else { return nil }
        return CGSize(width: proposal.width ?? uiView.intrinsicContentSize.width, height: height)
    }
}
