//
//  FormPaymentMethodTokenizationViewModel+FormViews.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

#if canImport(UIKit)

import UIKit

extension FormPaymentMethodTokenizationViewModel {
    
    // MARK: Input view
    
    func makeInputViews() -> [Input] {
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.config.type), inputPaymentMethodTypes.contains(paymentMethodType) else { return [] }
        
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
        
        let calendarImage = UIImage(named: "calendar", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        let calendarImageView = UIImageView(image: calendarImage)
        calendarImageView.tintColor = .gray600
        calendarImageView.clipsToBounds = true
        calendarImageView.contentMode = .scaleAspectFit
        dueAtContainerStackView.addArrangedSubview(calendarImageView)
        
        if let expDate = PrimerAPIConfigurationModule.decodedJWTToken?.expDate {
            let dueAtPrefixLabel = UILabel()
            let dueDateAttributedString = NSMutableAttributedString()
            let prefix = NSAttributedString(
                string: Strings.AccountInfoPaymentView.dueAt,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray600])
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
        
        let accountNumberInfoContainerStackView = PrimerStackView()
        accountNumberInfoContainerStackView.axis = .vertical
        accountNumberInfoContainerStackView.spacing = 12.0
        accountNumberInfoContainerStackView.addBackground(color: .gray100)
        accountNumberInfoContainerStackView.layoutMargins = UIEdgeInsets(top: PrimerDimensions.StackViewSpacing.default,
                                                                         left: PrimerDimensions.StackViewSpacing.default,
                                                                         bottom: PrimerDimensions.StackViewSpacing.default,
                                                                         right: PrimerDimensions.StackViewSpacing.default)
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
        accountNumberStackView.layoutMargins = UIEdgeInsets(top: PrimerDimensions.StackViewSpacing.default,
                                                            left: PrimerDimensions.StackViewSpacing.default,
                                                            bottom: PrimerDimensions.StackViewSpacing.default,
                                                            right: PrimerDimensions.StackViewSpacing.default)
        accountNumberStackView.layer.cornerRadius = PrimerDimensions.cornerRadius / 2
        accountNumberStackView.layer.borderColor = UIColor.gray200.cgColor
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
        
        let copyToClipboardImage = UIImage(named: "copy-to-clipboard", in: Bundle.primerResources, compatibleWith: nil)
        let copiedToClipboardImage = UIImage(named: "check-circle", in: Bundle.primerResources, compatibleWith: nil)
        let copyToClipboardButton = UIButton(type: .custom)
        copyToClipboardButton.setImage(copyToClipboardImage, for: .normal)
        copyToClipboardButton.setImage(copiedToClipboardImage, for: .selected)
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
            confirmationStepLabel.textColor = .gray600
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
        descriptionLabel.textColor = .gray600
        descriptionLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.body)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = Strings.VoucherInfoPaymentView.descriptionLabel
        
        // Expires at
        
        let expiresAtContainerStackView = UIStackView()
        expiresAtContainerStackView.axis = .horizontal
        expiresAtContainerStackView.spacing = 8.0
        
        let calendarImage = UIImage(named: "calendar", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        let calendarImageView = UIImageView(image: calendarImage)
        calendarImageView.tintColor = .gray600
        calendarImageView.clipsToBounds = true
        calendarImageView.contentMode = .scaleAspectFit
        expiresAtContainerStackView.addArrangedSubview(calendarImageView)
        
        if let expDate = PrimerAPIConfigurationModule.decodedJWTToken?.expiresAt {
            let expiresAtPrefixLabel = UILabel()
            let expiresAtAttributedString = NSMutableAttributedString()
            let prefix = NSAttributedString(
                string: Strings.VoucherInfoPaymentView.expiresAt,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray600])
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
        voucherInfoContainerStackView.layer.borderColor = UIColor.gray200.cgColor
        voucherInfoContainerStackView.layer.borderWidth = 2.0
        voucherInfoContainerStackView.isLayoutMarginsRelativeArrangement = true
        voucherInfoContainerStackView.layer.cornerRadius = 8.0
                        
        for voucherValue in VoucherValue.currentVoucherValues {
            
            if voucherValue.value != nil {
                
                let voucherValueStackView = PrimerStackView()
                voucherValueStackView.axis = .horizontal
                voucherValueStackView.spacing = 12.0
                voucherValueStackView.distribution = .fillProportionally
                
                let voucherValueLabel = UILabel()
                voucherValueLabel.text = voucherValue.description
                voucherValueLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
                voucherValueLabel.textColor = .gray600
                voucherValueStackView.addArrangedSubview(voucherValueLabel)
                
                let voucherValueText = UILabel()
                voucherValueText.text = voucherValue.value
                voucherValueText.font = UIFont.boldSystemFont(ofSize: PrimerDimensions.Font.label)
                voucherValueText.textColor = theme.text.title.color
                voucherValueText.setContentHuggingPriority(.required, for: .horizontal)
                voucherValueText.setContentCompressionResistancePriority(.required, for: .horizontal)
                voucherValueStackView.addArrangedSubview(voucherValueText)
                                
                voucherInfoContainerStackView.addArrangedSubview(voucherValueStackView)
                
                if let lastValue = VoucherValue.currentVoucherValues.last, voucherValue != lastValue  {
                    // Separator view
                    let separatorView = PrimerView()
                    separatorView.backgroundColor = .gray200
                    separatorView.translatesAutoresizingMaskIntoConstraints = false
                    separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
                    voucherInfoContainerStackView.addArrangedSubview(separatorView)
                }
            }
        }
        
        //        let copyToClipboardImage = UIImage(named: "copy-to-clipboard", in: Bundle.primerResources, compatibleWith: nil)
        //        let copiedToClipboardImage = UIImage(named: "check-circle", in: Bundle.primerResources, compatibleWith: nil)
        //        let copyToClipboardButton = UIButton(type: .custom)
        //        copyToClipboardButton.setImage(copyToClipboardImage, for: .normal)
        //        copyToClipboardButton.setImage(copiedToClipboardImage, for: .selected)
        //        copyToClipboardButton.translatesAutoresizingMaskIntoConstraints = false
        //        copyToClipboardButton.addTarget(self, action: #selector(copyToClipboardTapped), for: .touchUpInside)
        //        entityStackView.addArrangedSubview(copyToClipboardButton)
        
        self.uiModule.submitButton = nil
        
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
        
        log(logLevel: .debug, message: "📝📝📝📝 Copied: \(String(describing: UIPasteboard.general.string))")
        
        DispatchQueue.main.async {
            sender.isSelected = true
        }
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
            DispatchQueue.main.async {
                sender.isSelected = false
            }
            timer.invalidate()
        }
    }
}

extension FormPaymentMethodTokenizationViewModel {
    
    // MARK: Present appropriate View Controller
    
    func presentPaymentMethodAppropriateViewController(shouldCompletePaymentExternally: Bool = false) -> Promise<Void> {
        
        if shouldCompletePaymentExternally {
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.config.type),
                  let message = needingExternalCompletionPaymentMethodDictionary.first(where: { $0.key == paymentMethodType })?.value else {
                return Promise()
            }
            
            let infoView = makePaymentPendingInfoView(message: message)
            let paymentPendingInfoView = PrimerPaymentPendingInfoViewController(formPaymentMethodTokenizationViewModel: self, infoView: infoView)
            PrimerUIManager.primerRootViewController?.show(viewController: paymentPendingInfoView)
            return Promise()
        }
        
        if let paymentMethodType = PrimerPaymentMethodType(rawValue: self.config.type), inputPaymentMethodTypes.contains(paymentMethodType) {
            return presentInputViewController()
        }
                
        if let paymentMethodType = PrimerPaymentMethodType(rawValue: self.config.type), voucherPaymentMethodTypes.contains(paymentMethodType) {
            return presentVoucherInfoConfirmationStepViewController()
        }
        
        return Promise()
    }
    
    func presentVoucherInfoConfirmationStepViewController() -> Promise<Void> {
        return Promise { seal in
            let pcfvc = PrimerAccountInfoPaymentViewController(navigationBarLogo: uiModule.navigationBarLogo, formPaymentMethodTokenizationViewModel: self)
            infoView = voucherConfirmationInfoView
            PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
            seal.fulfill()
        }
    }
    
    func presentVoucherInfoViewController() {
        let pcfvc = PrimerVoucherInfoPaymentViewController(navigationBarLogo: uiModule.navigationBarLogo,
                                                           formPaymentMethodTokenizationViewModel: self,
                                                           shouldShareVoucherInfoWithText: VoucherValue.sharableVoucherValuesText)
        infoView = voucherInfoView
        PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
    }
    
    func presentAccountInfoViewController() {
        let pcfvc = PrimerAccountInfoPaymentViewController(navigationBarLogo: uiModule.navigationBarLogo, formPaymentMethodTokenizationViewModel: self)
        infoView = makeAccountInfoPaymentView()
        PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
    }
    
    func presentInputViewController() -> Promise<Void> {
        return Promise { seal in
            let pcfvc = PrimerInputViewController(navigationBarLogo: uiModule.navigationBarLogo, formPaymentMethodTokenizationViewModel: self, inputsDistribution: .horizontal)
            inputs.append(contentsOf: makeInputViews())
            PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
            seal.fulfill()
        }
    }
}

#endif
