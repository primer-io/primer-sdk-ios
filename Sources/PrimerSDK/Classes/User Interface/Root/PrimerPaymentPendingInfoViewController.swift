//
//  PrimerPaymentPendingInfoViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerUI
import UIKit

final class PrimerPaymentPendingInfoViewController: PrimerFormViewController {

    private let formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel
    private let infoView: PrimerFormView

    init(formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel, infoView: PrimerFormView) {
        self.formPaymentMethodTokenizationViewModel = formPaymentMethodTokenizationViewModel
        self.infoView = infoView
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        verticalStackView.addArrangedSubview(infoView)
    }
}
