//
//  FormPaymentMethodTokenizationViewModel+FormViews.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length

import UIKit

extension FormPaymentMethodTokenizationViewModel {

    // MARK: Input view

    func makeInputViews() -> [Input] {
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.config.type),
              inputPaymentMethodTypes.contains(paymentMethodType) else { return [] }

        switch paymentMethodType {
        case .adyenBlik:
            return [adyenBlikInputView]
        case .adyenMBWay:
            return [mbwayInputView]
        default:
            return []
        }
    }
}

extension FormPaymentMethodTokenizationViewModel {

    // MARK: Account Info Payment View

    func makeAccountInfoPaymentView() -> PrimerFormView? {

        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.config.type) else {
            return nil
        }

        switch paymentMethodType {
        case .rapydFast:
            return rapydFastAccountInfoView
        default:
            return nil
        }
    }
}

extension FormPaymentMethodTokenizationViewModel {

    // MARK: Rapyd Fast Account Info Payment View

    var rapydFastAccountInfoView: PrimerFormView {

        // Complete your payment

        let completeYourPaymentLabel = UILabel()
        completeYourPaymentLabel.text = Strings.AccountInfoPaymentView.completeYourPayment
        completeYourPaymentLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.title)
        completeYourPaymentLabel.textColor = theme.text.title.color

        // Due at

        let dueAtContainerStackView = UIStackView()
        dueAtContainerStackView.axis = .horizontal
        dueAtContainerStackView.spacing = 8.0

        let calendarImageView = UIImageView(image: .calendar?.withRenderingMode(.alwaysTemplate))
        calendarImageView.tintColor = .primerGray600
        calendarImageView.clipsToBounds = true
        calendarImageView.contentMode = .scaleAspectFit
        dueAtContainerStackView.addArrangedSubview(calendarImageView)

        if let expDate = PrimerAPIConfigurationModule.decodedJWTToken?.expDate {
            let dueAtPrefixLabel = UILabel()
            let dueDateAttributedString = NSMutableAttributedString()
            let prefix = NSAttributedString(
                string: Strings.AccountInfoPaymentView.dueAt,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.primerGray600])
            let formatter = DateFormatter().withExpirationDisplayDateFormat()
            let dueAtDate = NSAttributedString(
                string: formatter.string(from: expDate),
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            dueDateAttributedString.append(prefix)
            dueDateAttributedString.append(NSAttributedString(string: " ", attributes: nil))
            dueDateAttributedString.append(dueAtDate)
            dueAtPrefixLabel.attributedText = dueDateAttributedString
            dueAtPrefixLabel.numberOfLines = 0
            dueAtPrefixLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.body)
            dueAtContainerStackView.addArrangedSubview(dueAtPrefixLabel)
        }

        // Account number
        let spacing = PrimerDimensions.StackViewSpacing.default

        let accountNumberInfoContainerStackView = PrimerStackView()
        accountNumberInfoContainerStackView.axis = .vertical
        accountNumberInfoContainerStackView.spacing = 12.0
        accountNumberInfoContainerStackView.addBackground(color: .primerGray100)
        accountNumberInfoContainerStackView.layoutMargins = UIEdgeInsets(top: spacing,
                                                                         left: spacing,
                                                                         bottom: spacing,
                                                                         right: spacing)
        accountNumberInfoContainerStackView.isLayoutMarginsRelativeArrangement = true
        accountNumberInfoContainerStackView.layer.cornerRadius = PrimerDimensions.cornerRadius

        let transferFundsLabel = UILabel()
        transferFundsLabel.text = Strings.AccountInfoPaymentView.pleaseTransferFunds
        transferFundsLabel.numberOfLines = 0
        transferFundsLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
        transferFundsLabel.textColor = theme.text.title.color
        accountNumberInfoContainerStackView.addArrangedSubview(transferFundsLabel)

        let accountNumberStackView = PrimerStackView()
        accountNumberStackView.axis = .horizontal
        accountNumberStackView.spacing = 12.0
        accountNumberStackView.heightAnchor.constraint(equalToConstant: 56.0).isActive = true
        accountNumberStackView.addBackground(color: .white)
        accountNumberStackView.layoutMargins = UIEdgeInsets(top: spacing,
                                                            left: spacing,
                                                            bottom: spacing,
                                                            right: spacing)
        accountNumberStackView.layer.cornerRadius = PrimerDimensions.cornerRadius / 2
        accountNumberStackView.layer.borderColor = UIColor.primerGray200.cgColor
        accountNumberStackView.layer.borderWidth = 2.0
        accountNumberStackView.isLayoutMarginsRelativeArrangement = true
        accountNumberStackView.layer.cornerRadius = 8.0

        if let accountNumber = PrimerAPIConfigurationModule.decodedJWTToken?.accountNumber {
            let accountNumberLabel = UILabel()
            accountNumberLabel.text = accountNumber
            accountNumberLabel.font = UIFont.boldSystemFont(ofSize: PrimerDimensions.Font.label)
            accountNumberLabel.textColor = theme.text.title.color
            accountNumberStackView.addArrangedSubview(accountNumberLabel)
        }

        let copyToClipboardButton = UIButton(type: .custom)
        copyToClipboardButton.setImage(.copyToClipboard, for: .normal)
        copyToClipboardButton.setImage(.checkCircle, for: .selected)
        copyToClipboardButton.translatesAutoresizingMaskIntoConstraints = false
        copyToClipboardButton.addTarget(self, action: #selector(copyToClipboardTapped), for: .touchUpInside)
        accountNumberStackView.addArrangedSubview(copyToClipboardButton)

        accountNumberInfoContainerStackView.addArrangedSubview(accountNumberStackView)

        let views = [[completeYourPaymentLabel],
                     [dueAtContainerStackView],
                     [accountNumberInfoContainerStackView]]

        return PrimerFormView(formViews: views)
    }

}

extension FormPaymentMethodTokenizationViewModel {

    // MARK: Voucher Confirmation Info View

    var voucherConfirmationInfoView: PrimerFormView {

        // Complete your payment

        let confirmationTitleLabel = UILabel()
        confirmationTitleLabel.text = Strings.VoucherInfoConfirmationSteps.confirmationStepTitle
        confirmationTitleLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.title)
        confirmationTitleLabel.textColor = theme.text.title.color

        // Confirmation steps

        let confirmationStepContainerStackView = PrimerStackView()
        confirmationStepContainerStackView.axis = .vertical
        confirmationStepContainerStackView.spacing = 16.0
        confirmationStepContainerStackView.isLayoutMarginsRelativeArrangement = true

        let stepsTexts = [Strings.VoucherInfoConfirmationSteps.confirmationStep1LabelText,
                          Strings.VoucherInfoConfirmationSteps.confirmationStep2LabelText,
                          Strings.VoucherInfoConfirmationSteps.confirmationStep3LabelText]

        for stepsText in stepsTexts {

            let confirmationStepLabel = UILabel()
            confirmationStepLabel.textColor = .primerGray600
            confirmationStepLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
            confirmationStepLabel.numberOfLines = 0
            confirmationStepLabel.text = stepsText

            confirmationStepContainerStackView.addArrangedSubview(confirmationStepLabel)
        }

        let views = [[confirmationTitleLabel],
                     [confirmationStepContainerStackView]]

        return PrimerFormView(formViews: views)
    }

    // MARK: Voucher Info View

    var voucherInfoView: PrimerFormView {

        // Complete your payment

        let completeYourPaymentLabel = UILabel()
        completeYourPaymentLabel.text = Strings.VoucherInfoPaymentView.completeYourPayment
        completeYourPaymentLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.title)
        completeYourPaymentLabel.textColor = theme.text.title.color

        let descriptionLabel = UILabel()
        descriptionLabel.textColor = .primerGray600
        descriptionLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.body)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = Strings.VoucherInfoPaymentView.descriptionLabel

        // Expires at

        let expiresAtContainerStackView = UIStackView()
        expiresAtContainerStackView.axis = .horizontal
        expiresAtContainerStackView.spacing = 8.0

        let calendarImageView = UIImageView(image: .calendar?.withRenderingMode(.alwaysTemplate))
        calendarImageView.tintColor = .primerGray600
        calendarImageView.clipsToBounds = true
        calendarImageView.contentMode = .scaleAspectFit
        expiresAtContainerStackView.addArrangedSubview(calendarImageView)

        if let expDate = PrimerAPIConfigurationModule.decodedJWTToken?.expiresAt {
            let expiresAtPrefixLabel = UILabel()
            let expiresAtAttributedString = NSMutableAttributedString()
            let prefix = NSAttributedString(
                string: Strings.VoucherInfoPaymentView.expiresAt,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.primerGray600])
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let expiresAtDate = NSAttributedString(
                string: formatter.string(from: expDate),
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            expiresAtAttributedString.append(prefix)
            expiresAtAttributedString.append(NSAttributedString(string: " ", attributes: nil))
            expiresAtAttributedString.append(expiresAtDate)
            expiresAtPrefixLabel.attributedText = expiresAtAttributedString
            expiresAtPrefixLabel.numberOfLines = 0
            expiresAtPrefixLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.body)
            expiresAtContainerStackView.addArrangedSubview(expiresAtPrefixLabel)
        }

        // Voucher info container Stack View

        let voucherInfoContainerStackView = PrimerStackView()
        voucherInfoContainerStackView.axis = .vertical
        voucherInfoContainerStackView.spacing = 12.0
        voucherInfoContainerStackView.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        voucherInfoContainerStackView.layer.cornerRadius = PrimerDimensions.cornerRadius / 2
        voucherInfoContainerStackView.layer.borderColor = UIColor.primerGray200.cgColor
        voucherInfoContainerStackView.layer.borderWidth = 2.0
        voucherInfoContainerStackView.isLayoutMarginsRelativeArrangement = true
        voucherInfoContainerStackView.layer.cornerRadius = 8.0

        for voucherValue in VoucherValue.currentVoucherValues where voucherValue.value != nil {

            let voucherValueStackView = PrimerStackView()
            voucherValueStackView.axis = .horizontal
            voucherValueStackView.spacing = 12.0
            voucherValueStackView.distribution = .fillProportionally

            let voucherValueLabel = UILabel()
            voucherValueLabel.text = voucherValue.description
            voucherValueLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
            voucherValueLabel.textColor = .primerGray600
            voucherValueStackView.addArrangedSubview(voucherValueLabel)

            let voucherValueText = UILabel()
            voucherValueText.text = voucherValue.value
            voucherValueText.font = UIFont.boldSystemFont(ofSize: PrimerDimensions.Font.label)
            voucherValueText.textColor = theme.text.title.color
            voucherValueText.setContentHuggingPriority(.required, for: .horizontal)
            voucherValueText.setContentCompressionResistancePriority(.required, for: .horizontal)
            voucherValueStackView.addArrangedSubview(voucherValueText)

            voucherInfoContainerStackView.addArrangedSubview(voucherValueStackView)

            if let lastValue = VoucherValue.currentVoucherValues.last, voucherValue != lastValue {
                // Separator view
                let separatorView = PrimerView()
                separatorView.backgroundColor = .primerGray200
                separatorView.translatesAutoresizingMaskIntoConstraints = false
                separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
                voucherInfoContainerStackView.addArrangedSubview(separatorView)
            }
        }

        uiModule.submitButton = nil

        let views = [[completeYourPaymentLabel],
                     [expiresAtContainerStackView],
                     [voucherInfoContainerStackView]]

        return PrimerFormView(formViews: views)
    }
}

extension FormPaymentMethodTokenizationViewModel {

    // MARK: Payment Pending Info View

    func makePaymentPendingInfoView(logo: UIImage? = nil,
                                    message: String) -> PrimerFormView {

        // The top logo

        let logoImageView = UIImageView(image: logo ?? uiModule.navigationBarLogo)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        logoImageView.clipsToBounds = true
        logoImageView.contentMode = .scaleAspectFit

        // Message string

        let completeYourPaymentLabel = UILabel()
        completeYourPaymentLabel.numberOfLines = 0
        completeYourPaymentLabel.textAlignment = .center
        completeYourPaymentLabel.text = message
        completeYourPaymentLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
        completeYourPaymentLabel.textColor = theme.text.title.color

        let views = [[logoImageView],
                     [completeYourPaymentLabel]]

        return PrimerFormView(formViews: views)

    }

}

extension FormPaymentMethodTokenizationViewModel {

    @objc
    func copyToClipboardTapped(_ sender: UIButton) {

        UIPasteboard.general.string = PrimerAPIConfigurationModule.decodedJWTToken?.accountNumber

        self.logger.debug(message: "📝📝📝📝 Copied: \(String(describing: UIPasteboard.general.string))")

        DispatchQueue.main.async {
            sender.isSelected = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            sender.isSelected = false
        }
    }
}

extension FormPaymentMethodTokenizationViewModel {
    // MARK: Present appropriate View Controller

    func presentPaymentMethodAppropriateViewController(shouldCompletePaymentExternally: Bool = false) async throws {
        if shouldCompletePaymentExternally {
            await uiManager.primerRootViewController?.enableUserInteraction(true)

            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: config.type),
                  let message = needingExternalCompletionPaymentMethodDictionary
                  .first(where: { $0.key == paymentMethodType })?
                  .value
            else { return }

            let infoView = makePaymentPendingInfoView(message: message)
            let paymentPendingInfoView = await PrimerPaymentPendingInfoViewController(
                formPaymentMethodTokenizationViewModel: self,
                infoView: infoView
            )
            await uiManager.primerRootViewController?.show(viewController: paymentPendingInfoView)
        } else if let paymentMethodType = PrimerPaymentMethodType(rawValue: config.type) {
            if inputPaymentMethodTypes.contains(paymentMethodType) {
                return try await presentInputViewController()
            } else if voucherPaymentMethodTypes.contains(paymentMethodType) {
                return await presentVoucherInfoConfirmationStepViewController()
            }
        }
    }

    func presentVoucherInfoConfirmationStepViewController() async {
        let accountInfoViewController = await PrimerAccountInfoPaymentViewController(
            navigationBarLogo: uiModule.navigationBarLogo,
            formPaymentMethodTokenizationViewModel: self
        )
        infoView = voucherConfirmationInfoView
        await uiManager.primerRootViewController?.show(viewController: accountInfoViewController)
    }

    func presentVoucherInfoViewController() {
        let voucherText = VoucherValue.sharableVoucherValuesText
        let voucherInfoViewController = PrimerVoucherInfoPaymentViewController(
            navigationBarLogo: uiModule.navigationBarLogo,
            formPaymentMethodTokenizationViewModel: self,
            shouldShareVoucherInfoWithText: voucherText
        )
        infoView = voucherInfoView
        self.uiManager.primerRootViewController?.show(viewController: voucherInfoViewController)
    }

    func presentAccountInfoViewController() {
        let accountInfoViewController = PrimerAccountInfoPaymentViewController(
            navigationBarLogo: uiModule.navigationBarLogo,
            formPaymentMethodTokenizationViewModel: self
        )
        infoView = makeAccountInfoPaymentView()
        self.uiManager.primerRootViewController?.show(viewController: accountInfoViewController)
    }

    func presentInputViewController() async throws {
        let inputViewController = await PrimerInputViewController(
            navigationBarLogo: uiModule.navigationBarLogo,
            formPaymentMethodTokenizationViewModel: self,
            inputsDistribution: .horizontal
        )

        for newInput in makeInputViews() where !inputs.contains(where: { $0 === newInput }) {
            inputs.append(newInput)
        }

        await uiManager.primerRootViewController?.show(viewController: inputViewController)
    }
}

// swiftlint:enable file_length
