//
//  PayPalButtonsComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerBDCUI
import UIKit

enum PayPalButtonsComponent {
    static func register() {
        SDUIComponentRegistry.shared.register("paypal.buttons") { _ in
            PayPalPlaceholderButton()
        }
    }
}

private final class PayPalPlaceholderButton: UIButton {
    init() {
        super.init(frame: .zero)
        setTitle("Pay with PayPal", for: .normal)
        setTitleColor(UIColor(red: 0, green: 0.19, blue: 0.53, alpha: 1), for: .normal)
        titleLabel?.font = .boldSystemFont(ofSize: 16)
        backgroundColor = UIColor(red: 1.0, green: 0.77, blue: 0.22, alpha: 1)
        layer.cornerRadius = 8
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 50)
    }

    @objc private func didTap() {
        print("[PayPalButtons] tapped")
    }
}
