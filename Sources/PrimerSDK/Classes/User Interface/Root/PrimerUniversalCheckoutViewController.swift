//
//  PrimerUniversalCheckoutViewController.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import UIKit

final class PrimerUniversalCheckoutViewController: PrimerFormViewController {

    var savedCardView: CardButton!
    private var titleLabel: UILabel!
    private var savedPaymentMethodStackView: UIStackView!
    private var payButton: PrimerButton!
    private var selectedPaymentMethod: PrimerPaymentMethodTokenData?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private let paymentMethodConfigViewModels = PrimerAPIConfiguration.paymentMethodConfigViewModels
    private var onClientSessionActionUpdateCompletion: ((Error?) -> Void)?
    private var singleUsePaymentMethod: PrimerPaymentMethodTokenData?
    private var resumePaymentId: String?
    private var cardButtonViewModel: CardButtonViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        postUIEvent(.view, type: .view, in: .universalCheckout)
        title = Strings.CheckoutView.navBarTitle
        view.backgroundColor = theme.view.backgroundColor

        verticalStackView.spacing = 14.0

        renderAmount()
        renderSelectedPaymentInstrument()
        renderAvailablePaymentMethods()

        guard PrimerAPIConfigurationModule.decodedJWTToken != nil else { return }

        let vaultService: VaultServiceProtocol = VaultService(apiClient: PrimerAPIClient())
        Task {
            do {
                try await vaultService.fetchVaultedPaymentMethods()
                renderSelectedPaymentInstrument(insertAt: 1)
            } catch {
                let primerErr = error.asPrimerError
                PrimerDelegateProxy.primerDidFailWithError(primerErr, data: nil) { errorDecision in
                    switch errorDecision.type {
                    case .fail(let message):
                        DispatchQueue.main.async {
                            PrimerUIManager.dismissOrShowResultScreen(
                                type: .failure,
                                paymentMethodManagerCategories: [],
                                withMessage: message
                            )
                        }
                    }
                }
            }
        }
    }

    private func renderAmount() {
        let universalCheckoutViewModel: UniversalCheckoutViewModelProtocol = UniversalCheckoutViewModel()

        if let amountStr = universalCheckoutViewModel.amountStr {
            titleLabel = UILabel()
            titleLabel.accessibilityIdentifier = "Amount Label"
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
            titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
            titleLabel.text = amountStr
            titleLabel.textColor = theme.text.amountLabel.color
            verticalStackView.addArrangedSubview(titleLabel)
        }
    }

    private func renderSelectedPaymentInstrument(insertAt index: Int? = nil) {
        if savedCardView != nil {
            verticalStackView.removeArrangedSubview(savedCardView)
            savedCardView.removeFromSuperview()
            savedCardView = nil
        }

        if savedPaymentMethodStackView != nil {
            verticalStackView.removeArrangedSubview(savedPaymentMethodStackView)
            savedPaymentMethodStackView.removeFromSuperview()
            savedPaymentMethodStackView = nil
        }

        let universalCheckoutViewModel: UniversalCheckoutViewModelProtocol = UniversalCheckoutViewModel()

        if let selectedPaymentMethod = universalCheckoutViewModel.selectedPaymentMethod,
           let cardButtonViewModel = selectedPaymentMethod.cardButtonViewModel {
            self.cardButtonViewModel = cardButtonViewModel
            self.selectedPaymentMethod = selectedPaymentMethod

            if savedPaymentMethodStackView == nil {
                savedPaymentMethodStackView = UIStackView()
                savedPaymentMethodStackView.axis = .vertical
                savedPaymentMethodStackView.alignment = .fill
                savedPaymentMethodStackView.distribution = .fill
                savedPaymentMethodStackView.spacing = 5.0
            }

            let titleHorizontalStackView = UIStackView()
            titleHorizontalStackView.translatesAutoresizingMaskIntoConstraints = false
            titleHorizontalStackView.axis = .horizontal
            titleHorizontalStackView.alignment = .fill
            titleHorizontalStackView.distribution = .fill
            titleHorizontalStackView.spacing = 8.0

            let savedPaymentMethodLabel = UILabel()
            savedPaymentMethodLabel.translatesAutoresizingMaskIntoConstraints = false
            savedPaymentMethodLabel.text = Strings.VaultPaymentMethodViewContent.savedPaymentMethodsTitle.localizedUppercase
            savedPaymentMethodLabel.adjustsFontSizeToFitWidth = true
            savedPaymentMethodLabel.minimumScaleFactor = 0.8
            savedPaymentMethodLabel.textColor = theme.text.subtitle.color
            savedPaymentMethodLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            titleHorizontalStackView.addArrangedSubview(savedPaymentMethodLabel)

            let seeAllButton = UIButton()
            seeAllButton.translatesAutoresizingMaskIntoConstraints = false
            seeAllButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
            seeAllButton.setTitle(Strings.VaultPaymentMethodViewContent.seeAllButtonTitle, for: .normal)
            seeAllButton.titleLabel?.adjustsFontSizeToFitWidth = true
            seeAllButton.titleLabel?.minimumScaleFactor = 0.7
            seeAllButton.setTitleColor(theme.text.system.color, for: .normal)
            seeAllButton.addTarget(self, action: #selector(seeAllButtonTapped), for: .touchUpInside)
            titleHorizontalStackView.addArrangedSubview(seeAllButton)

            savedPaymentMethodStackView.addArrangedSubview(titleHorizontalStackView)

            let paymentMethodStackView = UIStackView()
            paymentMethodStackView.translatesAutoresizingMaskIntoConstraints = false
            paymentMethodStackView.layer.cornerRadius = 4.0
            paymentMethodStackView.clipsToBounds = true
            paymentMethodStackView.backgroundColor = UIColor.black.withAlphaComponent(0.05)
            paymentMethodStackView.axis = .vertical
            paymentMethodStackView.alignment = .fill
            paymentMethodStackView.distribution = .fill
            paymentMethodStackView.spacing = 8.0
            paymentMethodStackView.isLayoutMarginsRelativeArrangement = true
            paymentMethodStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

            guard var amount = AppState.current.amount,
                  let currency = AppState.current.currency
            else {
                let err = PrimerError.invalidValue(key: "amount or currency")
                Task {
                    let errMessage = await PrimerDelegateProxy.raisePrimerDidFailWithError(err, data: nil)
                    PrimerUIManager.dismissOrShowResultScreen(type: .failure,
                                                              paymentMethodManagerCategories: [],
                                                              withMessage: errMessage)
                }
                return
            }

            if let surCharge = cardButtonViewModel.surCharge {
                let surChargeLabel = UILabel()
                surChargeLabel.text = "+" + Int(surCharge).toCurrencyString(currency: currency)
                surChargeLabel.textColor = theme.text.body.color
                surChargeLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
                paymentMethodStackView.addArrangedSubview(surChargeLabel)

                amount += surCharge
            }

            if savedCardView == nil {
                savedCardView = CardButton()
                savedCardView.backgroundColor = .white
                savedCardView.translatesAutoresizingMaskIntoConstraints = false
                savedCardView.heightAnchor.constraint(equalToConstant: 64.0).isActive = true
                savedCardView.render(model: cardButtonViewModel)
                paymentMethodStackView.addArrangedSubview(savedCardView)
            }

            if payButton == nil {
                payButton = PrimerButton()
            }

            var title = Strings.PaymentButton.pay

            if amount != 0, let currency = AppState.current.currency {
                title += " \(amount.toCurrencyString(currency: currency))"
            }

            payButton.layer.cornerRadius = 4
            payButton.setTitle(title, for: .normal)
            payButton.setTitleColor(theme.mainButton.text.color, for: .normal)
            payButton.titleLabel?.font = .boldSystemFont(ofSize: 19)
            payButton.backgroundColor = theme.mainButton.color(for: .enabled)
            payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
            payButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            payButton.accessibilityIdentifier = "payAllButton"
            paymentMethodStackView.addArrangedSubview(payButton)

            if !paymentMethodStackView.arrangedSubviews.isEmpty {
                savedPaymentMethodStackView.addArrangedSubview(paymentMethodStackView)
            }

            if let index = index {
                verticalStackView.insertArrangedSubview(savedPaymentMethodStackView, at: index)
            } else {
                verticalStackView.addArrangedSubview(savedPaymentMethodStackView)
            }
        } else {
            if savedCardView != nil {
                verticalStackView.removeArrangedSubview(savedCardView)
                savedCardView.removeFromSuperview()
                savedCardView = nil
            }

            if savedPaymentMethodStackView != nil {
                verticalStackView.removeArrangedSubview(savedPaymentMethodStackView)
                savedPaymentMethodStackView.removeFromSuperview()
                savedPaymentMethodStackView = nil
            }
        }

        (self.parent as? PrimerContainerViewController)?.layoutContainerViewControllerIfNeeded {
            self.verticalStackView.layoutIfNeeded()
        }

        PrimerUIManager.primerRootViewController?.layoutIfNeeded()
    }

    private func renderAvailablePaymentMethods() {
        PrimerFormViewController.renderPaymentMethods(paymentMethodConfigViewModels, on: verticalStackView)
    }

    @objc
    func seeAllButtonTapped(_ sender: Any) {
        postUIEvent(.click, type: .button, in: .universalCheckout, id: .seeAll)
        let vpivc = VaultedPaymentInstrumentsViewController()
        vpivc.delegate = self
        vpivc.view.translatesAutoresizingMaskIntoConstraints = false
        vpivc.view.heightAnchor.constraint(equalToConstant: self.parent!.view.bounds.height).isActive = true
        PrimerUIManager.primerRootViewController?.show(viewController: vpivc)
    }

    @objc
    func payButtonTapped() {
        guard let selectedPaymentMethod = selectedPaymentMethod else { return }
        guard let selectedPaymentMethodType = selectedPaymentMethod.paymentMethodType else { return }
        guard let config = PrimerAPIConfiguration.paymentMethodConfigs?.filter({ $0.type == selectedPaymentMethodType }).first else {
            return
        }
        let context = AnalyticsContext(paymentMethodType: config.type)
        postUIEvent(.click, context: context, type: .button, in: .universalCheckout, id: .pay)
        if let captureVaultedCardCvv = (config.options as? CardOptions)?.captureVaultedCardCvv,
           captureVaultedCardCvv == true,
           config.internalPaymentMethodType == .paymentCard {
            let cvvViewController = CVVRecaptureViewController(viewModel: CVVRecaptureViewModel())
            cvvViewController.viewModel.cardButtonViewModel = cardButtonViewModel
            cvvViewController.viewModel.didSubmitCvv = { [weak self] cvv in
                let cvvData = PrimerVaultedCardAdditionalData(cvv: cvv)
                startCheckout(withAdditionalData: cvvData)
                self?.postUIEvent(.click, context: context, type: .button, in: .cvvRecapture, id: .submit)
            }

            PrimerUIManager.primerRootViewController?.show(viewController: cvvViewController, animated: true)
            postUIEvent(.present, context: context, type: .view, in: .cvvRecapture)
        } else {
            startCheckout(withAdditionalData: nil)
        }

        // Common functionality to start the checkout process
        func startCheckout(withAdditionalData additionalData: PrimerVaultedCardAdditionalData?) {
            payButton.startAnimating()
            enableView(false)

            let checkoutWithVaultedPaymentMethodVM = CheckoutWithVaultedPaymentMethodViewModel(
                configuration: config,
                selectedPaymentMethodTokenData: selectedPaymentMethod,
                additionalData: additionalData,
                createResumePaymentService: CreateResumePaymentService(paymentMethodType: selectedPaymentMethodType))

            Task {
                try? await checkoutWithVaultedPaymentMethodVM.start()
                self.payButton.stopAnimating()
                self.enableView(true)
            }
        }
    }
}

extension PrimerUniversalCheckoutViewController {

    private func enableView(_ isEnabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.view?.isUserInteractionEnabled = isEnabled
            (self?.parent as? PrimerContainerViewController)?.scrollView.isScrollEnabled = isEnabled
            PrimerUIManager.primerRootViewController?.enableUserInteraction(isEnabled)

            for stackView in (self?.verticalStackView.arrangedSubviews ?? []) {
                stackView.alpha = stackView == self?.savedPaymentMethodStackView ? 1.0 : (isEnabled ? 1.0 : 0.5)
            }

            for stackView in (self?.savedPaymentMethodStackView.arrangedSubviews ?? []) {
                if let stackView = stackView as? UIStackView, !stackView.arrangedSubviews.filter({ $0 is PrimerButton }).isEmpty {
                    for ssv in stackView.arrangedSubviews {
                        if ssv is PrimerButton {
                            ssv.alpha = 1.0
                        } else {
                            ssv.alpha = (isEnabled ? 1.0 : 0.5)
                        }
                    }
                } else {
                    stackView.alpha = (isEnabled ? 1.0 : 0.5)
                }
            }
        }
    }
}

extension PrimerUniversalCheckoutViewController: ReloadDelegate {
    func reload() {
        renderSelectedPaymentInstrument(insertAt: 1)
    }
}

// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
