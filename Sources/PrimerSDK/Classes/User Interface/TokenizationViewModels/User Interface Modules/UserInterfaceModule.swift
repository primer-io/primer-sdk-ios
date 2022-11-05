//
//  UserInterfaceModule.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//


#if canImport(UIKit)

import UIKit

protocol UserInterfaceModuleProtocol: NSObject {
    
    var logo: UIImage? { get }
    var navigationBarLogo: UIImage? { get }
    var icon: UIImage? { get }
    var surchargeSectionText: String? { get }
    var paymentMethodButton: PrimerButton? { get }
    var submitButton: PrimerButton? { get }
    
    init(paymentMethodConfiguration: PrimerPaymentMethod,
         tokenizationModule: TokenizationModuleProtocol,
         paymentModule: PaymentModuleProtocol)
    
    func presentPreTokenizationViewControllerIfNeeded() -> Promise<Void>
    func presentPostPaymentViewControllerIfNeeded() -> Promise<Void>
    func presentResultViewControllerIfNeeded() -> Promise<Void>
    
    func dismisPresentedViewControllerIfNeeded() -> Promise<Void>
}

class NewUserInterfaceModule: NSObject, UserInterfaceModuleProtocol {
    
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    var logo: UIImage? {
        paymentMethodConfiguration.logo
    }
    
    var navigationBarLogo: UIImage? {
        logo
    }
    
    var icon: UIImage? {
        var fileName = paymentMethodConfiguration.type.lowercased().replacingOccurrences(of: "_", with: "-")
        fileName += "-icon"
        
        switch self.themeMode {
        case .colored:
            fileName += "-colored"
        case .dark:
            fileName += "-dark"
        case .light:
            fileName += "-colored"
        }
        
        return UIImage(named: fileName, in: Bundle.primerResources, compatibleWith: nil)
    }
    
    var surchargeSectionText: String? {
        guard let currency = AppState.current.currency else { return nil }
        guard let availablePaymentMethods = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods, !availablePaymentMethods.isEmpty else { return nil }
        guard let str = availablePaymentMethods.filter({ $0.type == self.paymentMethodConfiguration.type }).first?.surcharge?.toCurrencyString(currency: currency) else { return nil }
        return "+\(str)"
    }
    
    lazy var resultView: PrimerView? = {
        fatalError("`resultView` must be overridden")
    }()
    lazy var inputView: PrimerView? = {
        fatalError("`inputView` must be overridden")
    }()
    
    lazy var paymentMethodButton: PrimerButton? = nil
    lazy var submitButton: PrimerButton? = nil
    
    var presentedViewController: UIViewController?
    
    var themeMode: PrimerTheme.Mode {
        if let baseLogoImage = paymentMethodConfiguration.baseLogoImage {
            if UIScreen.isDarkModeEnabled {
                if baseLogoImage.dark != nil {
                    return .dark
                } else if baseLogoImage.colored != nil {
                    return .colored
                } else if baseLogoImage.light != nil {
                    return .light
                }
            } else {
                if baseLogoImage.colored != nil {
                    return .colored
                } else if baseLogoImage.light != nil {
                    return .light
                } else if baseLogoImage.dark != nil {
                    return .dark
                }
            }
        }
        
        if UIScreen.isDarkModeEnabled {
            return .dark
        } else {
            return .colored
        }
    }
    
    weak var paymentMethodConfiguration: PrimerPaymentMethod!
    weak var tokenizationModule: TokenizationModuleProtocol!
    weak var paymentModule: PaymentModuleProtocol!
    
    required init(paymentMethodConfiguration: PrimerPaymentMethod, tokenizationModule: TokenizationModuleProtocol, paymentModule: PaymentModuleProtocol) {
        self.paymentMethodConfiguration = paymentMethodConfiguration
        self.tokenizationModule = tokenizationModule
        self.paymentModule = paymentModule
    }
        
    func presentPreTokenizationViewControllerIfNeeded() -> Promise<Void> {
        fatalError("presentPreTokenizationViewControllerIfNeeded() has not been implemented")
    }
        
    func presentPostPaymentViewControllerIfNeeded() -> Promise<Void> {
        fatalError("presentPostPaymentViewControllerIfNeeded() has not been implemented")
    }
    
    func presentResultViewControllerIfNeeded() -> Promise<Void> {
        fatalError("presentResultViewControllerIfNeeded() has not been implemented")
    }
    
    func dismisPresentedViewControllerIfNeeded() -> Promise<Void> {
        return Promise { seal in
            self.presentedViewController?.dismiss(animated: true)
            seal.fulfill()
        }
    }
}

class UserInterfaceModule: NSObject {
    
    // MARK: - PROPERTIES
    
    weak var paymentMethodModule: PaymentMethodModuleProtocol!
    internal let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    internal lazy var paymentMethodType: PrimerPaymentMethodType? = {
        return PrimerPaymentMethodType(rawValue: self.paymentMethodModule.paymentMethodConfiguration.type)
    }()
        
    var themeMode: PrimerTheme.Mode {
        if let baseLogoImage = paymentMethodModule.paymentMethodConfiguration.baseLogoImage {
            if UIScreen.isDarkModeEnabled {
                if baseLogoImage.dark != nil {
                    return .dark
                } else if baseLogoImage.colored != nil {
                    return .colored
                } else if baseLogoImage.light != nil {
                    return .light
                }
            } else {
                if baseLogoImage.colored != nil {
                    return .colored
                } else if baseLogoImage.light != nil {
                    return .light
                } else if baseLogoImage.dark != nil {
                    return .dark
                }
            }
        }
        
        if UIScreen.isDarkModeEnabled {
            return .dark
        } else {
            return .colored
        }
    }
    
    var surchargeSectionText: String? {
        switch self.paymentMethodModule.paymentMethodConfiguration.type {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            return Strings.CardFormView.additionalFeesTitle
        default:
            guard let currency = AppState.current.currency else { return nil }
            guard let availablePaymentMethods = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods, !availablePaymentMethods.isEmpty else { return nil }
            guard let str = availablePaymentMethods.filter({ $0.type == self.paymentMethodModule.paymentMethodConfiguration.type }).first?.surcharge?.toCurrencyString(currency: currency) else { return nil }
            return "+\(str)"
        }
    }
        
    // MARK: - INITIALIZATION
    
    required init(paymentMethodModule: PaymentMethodModuleProtocol) {
        self.paymentMethodModule = paymentMethodModule
    }
    
    // MARK: - ACTIONS
    
    @IBAction internal func paymentMethodButtonTapped(_ sender: UIButton) {
        self.paymentMethodModule.startFlow()
    }
    
    @IBAction internal func submitButtonTapped(_ sender: UIButton) {
        self.paymentMethodModule.tokenizationModule.submitTokenizationData()
        //        self.paymentMethodModule.tokenizationModule.submitButtonTapped()
    }
    
    // MARK: - IMAGES
    
    internal var logo: UIImage? {
        return paymentMethodModule.paymentMethodConfiguration.logo
    }
    
    internal var invertedLogo: UIImage? {
        return paymentMethodModule.paymentMethodConfiguration.invertedLogo
    }
    
    var icon: UIImage? {
        var fileName = paymentMethodModule.paymentMethodConfiguration.type.lowercased().replacingOccurrences(of: "_", with: "-")
        fileName += "-icon"
        
        switch self.themeMode {
        case .colored:
            fileName += "-colored"
        case .dark:
            fileName += "-dark"
        case .light:
            fileName += "-colored"
        }
        
        return UIImage(named: fileName, in: Bundle.primerResources, compatibleWith: nil)
    }
    
    // MARK: - BUTTONS & VIEWS
    
    lazy var paymentMethodButton: PrimerButton = {
        let paymentMethodButtonBuilder = UserInterfaceModule.PaymentMethodButtonBuilder(paymentMethodConfiguration: self.paymentMethodModule.paymentMethodConfiguration)
        paymentMethodButtonBuilder.button.addTarget(self, action: #selector(paymentMethodButtonTapped(_:)), for: .touchUpInside)
        return paymentMethodButtonBuilder.button
    }()
    
    lazy var submitButton: PrimerButton? = {
        guard let paymentMethodType = self.paymentMethodType else { return nil }
        
        var title: String = ""
        
        switch paymentMethodType {
        case .paymentCard,
                .adyenMBWay:
            switch PrimerInternal.shared.intent {
            case .checkout:
                let universalCheckoutViewModel: UniversalCheckoutViewModelProtocol = UniversalCheckoutViewModel()
                title = Strings.PaymentButton.pay
                if let amountStr = universalCheckoutViewModel.amountStr {
                    title += " \(amountStr))"
                }
                
            case .vault:
                title = Strings.PrimerCardFormView.addCardButtonTitle
                
            case .none:
                precondition(false, "Intent should have been set")
            }
            
            return makePrimerButtonWithTitleText(title, isEnabled: false)
            
        case .primerTestKlarna,
                .primerTestPayPal,
                .primerTestSofort:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.pay, isEnabled: false)
            
        case .adyenBlik,
                .xfersPayNow:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.confirm, isEnabled: false)
            
        case .adyenMultibanco:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.confirmToPay, isEnabled: true)
            
        case .adyenBancontactCard:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.pay, isEnabled: false)
            
        default:
            return nil
        }
    }()
            
    // MARK: - INPUT VIEWS
        
    // MARK: - Rapyd Fast Input View
    
    internal var rapydFastAccountInfoView: PrimerFormView {
        
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
    
    // MARK: - VIEW CONTROLLERS
        
}

extension NewUserInterfaceModule {
    
    internal func createBanksSelectorViewController(with banks: [AdyenBank]) -> BankSelectorViewController {
        let bsvc = BankSelectorViewController(
            paymentMethodType: self.paymentMethodConfiguration.type,
            navigationBarImage: self.navigationBarLogo,
            banks: banks)
        return bsvc
    }
    
    internal func makeIconImageView(withDimension dimension: CGFloat) -> UIImageView? {
        guard let squareLogo = self.icon else { return nil }
        let imgView = UIImageView()
        imgView.image = squareLogo
        imgView.contentMode = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.heightAnchor.constraint(equalToConstant: dimension).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: dimension).isActive = true
        return imgView
    }

}

#endif
