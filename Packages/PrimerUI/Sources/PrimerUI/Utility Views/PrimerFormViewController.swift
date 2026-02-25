//
//  PrimerFormViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerUI
import UIKit

open class PrimerFormViewController: PrimerViewController {

    public var verticalStackView: UIStackView = UIStackView()

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(verticalStackView)

        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.alignment = .fill
        verticalStackView.axis = .vertical
        verticalStackView.distribution = .fill

        verticalStackView.pin(view: view, leading: 20, top: 20, trailing: -20, bottom: -20)
    }
}
// swiftlint:enable function_body_length
// swiftlint:enable line_length
