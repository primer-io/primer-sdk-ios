//
//  PrimerAccountInfoPaymentViewController.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

import UIKit

final class PrimerAccountInfoPaymentViewController: PrimerFormViewController {

    let formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel

    init(navigationBarLogo: UIImage?, formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel) {
        self.formPaymentMethodTokenizationViewModel = formPaymentMethodTokenizationViewModel
        super.init()
        self.titleImage = navigationBarLogo
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        verticalStackView.spacing = 16

        if let infoView = self.formPaymentMethodTokenizationViewModel.infoView {
            verticalStackView.addArrangedSubview(infoView)
        }

        if let submitButton = self.formPaymentMethodTokenizationViewModel.uiModule.submitButton {
            verticalStackView.addArrangedSubview(submitButton)
        }
    }

}
