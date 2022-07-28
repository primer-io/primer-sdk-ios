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
        guard inputPaymentMethodTypes.contains(self.config.type) else { return [] }
        
        switch self.config.type {
        case PrimerPaymentMethodType.adyenBlik.rawValue:
            return [adyenBlikInputView]
        case .mbway:
            return [mbwayInputView]
        default:
            return []
        }
    }
    
    // MARK: Adyen Blik Input View
    
    private var adyenBlikInputView: Input {
        let input1 = Input()
        input1.name = "OTP"
        input1.topPlaceholder = Strings.Blik.inputTopPlaceholder
        input1.textFieldPlaceholder = Strings.Blik.inputTextFieldPlaceholder
        input1.keyboardType = .numberPad
        input1.descriptor = Strings.Blik.inputDescriptor
        input1.allowedCharacterSet = CharacterSet(charactersIn: "0123456789")
        input1.maxCharactersAllowed = 6
        input1.isValid = { text in
            return text.isNumeric && text.count >= 6
        }
        return input1
    }
    
    private var mbwayInputView: Input {
        let input1 = Input()
        input1.name = "Phone Number"
        input1.topPlaceholder = Strings.Blik.inputTopPlaceholder
        input1.keyboardType = .numberPad
        input1.descriptor = Strings.Blik.inputDescriptor
        input1.allowedCharacterSet = CharacterSet(charactersIn: "0123456789")
        input1.isValid = { text in
            return text.isNumeric
        }
        return input1
    }
}

extension FormPaymentMethodTokenizationViewModel {
    
    // MARK: Account Info Payment View
    
    func makeAccountInfoPaymentView() -> PrimerFormView? {
        
        switch self.config.type {
        case PrimerPaymentMethodType.rapydFast.rawValue:
            return rapydFastAccountInfoView
        default:
            return nil
        }
    }
    
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
        
        if let expDate = ClientTokenService.decodedClientToken?.expDate {
            let dueAtPrefixLabel = UILabel()
            let dueDateAttributedString = NSMutableAttributedString()
            let prefix = NSAttributedString(
                string: Strings.AccountInfoPaymentView.dueAt,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray600])
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
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

        if let accountNumber = ClientTokenService.decodedClientToken?.accountNumber {
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
    
    @objc
    func copyToClipboardTapped(_ sender: UIButton) {
        
        UIPasteboard.general.string = ClientTokenService.decodedClientToken?.accountNumber
        
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
    
    func presentPaymentMethodAppropriateViewController() -> Promise<Void> {
        if inputPaymentMethodTypes.contains(self.config.type) {
            return presentInputViewController()
        }
        
        if accountInfoPaymentMethodTypes.contains(self.config.type) {
            return presentAccountInfoViewController()
        }
        
        return Promise()
    }
    
    func presentAccountInfoViewController() -> Promise<Void> {
        return Promise { seal in
            let pcfvc = PrimerAccountInfoPaymentViewController(navigationBarLogo: self.uiModule.buttonImage, formPaymentMethodTokenizationViewModel: self)
            accountInfoView = makeAccountInfoPaymentView()
            Primer.shared.primerRootVC?.show(viewController: pcfvc)
            seal.fulfill()
        }
    }
    
    func presentInputViewController() -> Promise<Void> {
        return Promise { seal in
            let pcfvc = PrimerInputViewController(navigationBarLogo: UIImage(named: "blik-logo-black", in: Bundle.primerResources, compatibleWith: nil), formPaymentMethodTokenizationViewModel: self)
            inputs.append(contentsOf: makeInputViews())
            Primer.shared.primerRootVC?.show(viewController: pcfvc)
            seal.fulfill()
        }
    }
}

#endif
