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
    
    var surchargeSectionText: String? {
        switch self.paymentMethodConfiguration.type {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            return Strings.CardFormView.additionalFeesTitle
        default:
            guard let currency = AppState.current.currency else { return nil }
            guard let availablePaymentMethods = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods, !availablePaymentMethods.isEmpty else { return nil }
            guard let str = availablePaymentMethods.filter({ $0.type == self.paymentMethodConfiguration.type }).first?.surcharge?.toCurrencyString(currency: currency) else { return nil }
            return "+\(str)"
        }
    }

    var logo: UIImage? {
        paymentMethodConfiguration.logo
    }
    
    var navigationBarLogo: UIImage? {
        logo
    }
    
    var submitButton: PrimerButton? {
        get { _submitButton }
        set { _submitButton = newValue }
    }

    var paymentMethodButton: PrimerButton? {
        get { _paymentMethodButton }
        set { _paymentMethodButton = newValue }
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
        
    lazy var resultView: PrimerView? = {
        fatalError("`resultView` must be overridden")
    }()
    
    lazy var inputView: PrimerView? = {
        fatalError("`inputView` must be overridden")
    }()
    
    private lazy var _paymentMethodButton: PrimerButton? = {
        let paymentMethodButtonBuilder = NewUserInterfaceModule.PaymentMethodButtonBuilder(paymentMethodConfiguration: self.paymentMethodConfiguration)
        paymentMethodButtonBuilder.button.addTarget(self, action: #selector(paymentMethodButtonTapped(_:)), for: .touchUpInside)
        return paymentMethodButtonBuilder.button
    }()

    private lazy var _submitButton: PrimerButton? = {
        
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type) else { return nil }

        switch paymentMethodType {
        case .paymentCard:

            var title: String = Strings.PaymentButton.pay

            switch PrimerInternal.shared.intent {
            case .checkout:
                let universalCheckoutViewModel: UniversalCheckoutViewModelProtocol = UniversalCheckoutViewModel()
                if let amountStr = universalCheckoutViewModel.amountStr {
                    title += " \(amountStr))"
                }

            case .vault:
                title = Strings.PrimerCardFormView.addCardButtonTitle

            case .none:
                precondition(false, "Intent should have been set")
            }

            return makePrimerButtonWithTitleText(title, isEnabled: false)

        default:
            return nil
        }
        
    }()

    
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
    
    // MARK: - ACTIONS
    
    @IBAction internal func paymentMethodButtonTapped(_ sender: UIButton) {
        self.paymentMethodConfiguration.paymentMethodModule?.startFlow()
    }
    
    @IBAction internal func submitButtonTapped(_ sender: UIButton) {
        self.tokenizationModule.submitTokenizationData()
    }
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
