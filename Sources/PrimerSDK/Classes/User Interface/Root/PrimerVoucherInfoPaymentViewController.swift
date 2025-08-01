//
//  PrimerVoucherInfoPaymentViewController.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

final class PrimerVoucherInfoPaymentViewController: PrimerFormViewController {

    let formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel
    let textToShare: String?
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    lazy var shareButton: UIButton = {
        let lazyShareButton = UIButton()
        lazyShareButton.setTitle(Strings.Generic.share, for: .normal)
        lazyShareButton.setTitleColor(theme.text.title.color, for: .normal)
        lazyShareButton.titleLabel?.numberOfLines = 1
        lazyShareButton.titleLabel?.adjustsFontSizeToFitWidth = true
        lazyShareButton.titleLabel?.minimumScaleFactor = 0.5
        lazyShareButton.addTarget(self, action: #selector(shareVoucherInfoTapped(_:)), for: .touchUpInside)
        return lazyShareButton
    }()

    init(navigationBarLogo: UIImage?, formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel, shouldShareVoucherInfoWithText textToShare: String? = nil) {
        self.formPaymentMethodTokenizationViewModel = formPaymentMethodTokenizationViewModel
        self.textToShare = textToShare
        super.init()
        self.titleImage = navigationBarLogo
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (parent as? PrimerContainerViewController)?.mockedNavigationBar.leftBarButton = shareButton
    }

}

extension PrimerVoucherInfoPaymentViewController {

    @IBAction func shareVoucherInfoTapped(_ sender: UIButton) {

        guard let textToShare = textToShare else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
}
