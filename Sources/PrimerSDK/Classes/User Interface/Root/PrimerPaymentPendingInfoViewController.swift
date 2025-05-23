//
//  PrimerPaymentPendingInfoViewController.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 22/08/22.
//

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
