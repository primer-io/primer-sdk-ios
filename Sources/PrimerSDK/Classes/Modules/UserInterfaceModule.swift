//
//  UserInterfaceModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 8/7/22.
//

#if canImport(UIKit)

protocol UserInterfaceModuleProtocol {
    
    var paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol { get }
    var logo: UIImage? { get }
    var icon: UIImage? { get }
    var surchargeSectionText: String? { get }
    var paymentMethodButton: PrimerButton { get }
    var submitButton: PrimerButton? { get }
    
    init(paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol)
    func makeLogoImageView(withSize size: CGSize?) -> UIImageView?
    func makeIconImageView(withDimension dimension: CGFloat) -> UIImageView?
}

import UIKit

class UserInterfaceModule: NSObject, UserInterfaceModuleProtocol {
    
    // MARK: - PROPERTIES
    
    var paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    lazy var logo: UIImage? = {
        guard let imageName = paymentMethodTokenizationViewModel.config.imageFiles?.colored.image else { return nil }
        return UIImage(named: "\(imageName)-logo", in: Bundle.primerResources, compatibleWith: nil)
    }()
    
    lazy var icon: UIImage? = {
        guard let imageName = paymentMethodTokenizationViewModel.config.imageFiles?.colored.image else { return nil }
        
        // In case we don't have a square icon, we show the icon image
        let imageLogoSquare = UIImage(named: "\(imageName)-logo-square", in: Bundle.primerResources, compatibleWith: nil)
        let imageIcon = UIImage(named: "\(imageName)-icon", in: Bundle.primerResources, compatibleWith: nil)
        return imageLogoSquare ?? imageIcon
    }()
    
    lazy var surchargeSectionText: String? = {
        switch paymentMethodTokenizationViewModel.config.type {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            return NSLocalizedString("surcharge-additional-fee",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Additional fee may apply",
                                     comment: "Additional fee may apply - Surcharge (Label)")
        default:
            guard let currency = AppState.current.currency else { return nil }
            guard let availablePaymentMethods = AppState.current.apiConfiguration?.paymentMethods, !availablePaymentMethods.isEmpty else { return nil }
            guard let str = availablePaymentMethods.filter({ $0.type == paymentMethodTokenizationViewModel.config.type }).first?.surcharge?.toCurrencyString(currency: currency) else { return nil }
            return "+\(str)"
        }
    }()
    
    lazy var buttonTitle: String? = {
        switch paymentMethodTokenizationViewModel.config.type {
        case PrimerPaymentMethodType.apaya.rawValue:
            return NSLocalizedString(paymentMethodTokenizationViewModel.config.data?.button.text ?? "payment-method-type-pay-by-mobile",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: paymentMethodTokenizationViewModel.config.data?.button.text ?? "Pay by mobile",
                                     comment: "Pay by mobile - Payment By Mobile (Apaya)")
            
        case PrimerPaymentMethodType.paymentCard.rawValue:
            return Primer.shared.intent == .vault
            ? NSLocalizedString(paymentMethodTokenizationViewModel.config.data?.button.text ?? "payment-method-type-card-vaulted",
                                tableName: nil,
                                bundle: Bundle.primerResources,
                                value: paymentMethodTokenizationViewModel.config.data?.button.text ?? "Add new card",
                                comment: "Add new card - Payment Method Type (Card Vaulted)")
            
            : NSLocalizedString(paymentMethodTokenizationViewModel.config.data?.button.text ?? "payment-method-type-card-not-vaulted",
                                tableName: nil,
                                bundle: Bundle.primerResources,
                                value: paymentMethodTokenizationViewModel.config.data?.button.text ?? "Pay with card",
                                comment: "Pay with card - Payment Method Type (Card Not vaulted)")

		case .twoCtwoP:
            return Strings.PaymentButton.payInInstallments
            
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    lazy var buttonImage: UIImage? = {
        return paymentMethodTokenizationViewModel.config.imageFiles?.colored.image
    }()
    
    lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    lazy var buttonCornerRadius: CGFloat? = {
        guard let cornerRadius = paymentMethodTokenizationViewModel.config.data?.button.cornerRadius else { return 4.0 }
        return CGFloat(cornerRadius)
    }()
    
    lazy var buttonColor: UIColor? = {
        guard let hexColor = paymentMethodTokenizationViewModel.config.data?.button.backgroundColor?.colored else { return nil }
        return PrimerColor(hex: hexColor)
    }()
    
    lazy var buttonTitleColor: UIColor? = {
        var titleColor: UIColor?
        if let coloredVal = paymentMethodTokenizationViewModel.config.data?.button.textColor?.colored {
            return PrimerColor(hex: coloredVal)
        }
        
        switch paymentMethodTokenizationViewModel.config.type {
        case PrimerPaymentMethodType.apaya.rawValue,
            PrimerPaymentMethodType.paymentCard.rawValue:
            return theme.paymentMethodButton.text.color
            
        default:
            return nil
        }
    }()
    
    lazy var buttonBorderWidth: CGFloat = {
        guard let borderWidth = paymentMethodTokenizationViewModel.config.data?.button.borderWidth else { return 0.0 }
        return CGFloat(borderWidth)
    }()
    
    lazy var buttonBorderColor: UIColor? = {
        guard let borderHexColor = paymentMethodTokenizationViewModel.config.data?.button.borderColor?.colored else { return nil }
        return PrimerColor(hex: borderHexColor)
    }()
    
    var buttonTintColor: UIColor? {
        return nil
    }
    
    var paymentMethodButton: PrimerButton {
        let customPaddingSettingsCard: [String] = [
            PrimerPaymentMethodType.coinbase.rawValue,
            PrimerPaymentMethodType.paymentCard.rawValue
        ]
        
        let paymentMethodButton = PrimerButton()
        paymentMethodButton.accessibilityIdentifier = paymentMethodTokenizationViewModel.config.type
        paymentMethodButton.clipsToBounds = true
        paymentMethodButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        let imagePadding: CGFloat = 20
        let leftPadding = UILocalizableUtil.isRightToLeftLocale ? imagePadding : 0
        let defaultRightPadding = customPaddingSettingsCard.contains(paymentMethodTokenizationViewModel.config.type) ? imagePadding : 0
        let rightPadding = UILocalizableUtil.isRightToLeftLocale ? 0 : defaultRightPadding
        paymentMethodButton.imageEdgeInsets = UIEdgeInsets(top: 5,
                                                           left: leftPadding,
                                                           bottom: 5,
                                                           right: rightPadding)
        paymentMethodButton.contentMode = .scaleAspectFit
        paymentMethodButton.imageView?.contentMode = .scaleAspectFit
        paymentMethodButton.titleLabel?.font = buttonFont
        if let buttonCornerRadius = buttonCornerRadius {
            paymentMethodButton.layer.cornerRadius = buttonCornerRadius
        }
        paymentMethodButton.backgroundColor = buttonColor
        paymentMethodButton.setTitle(self.buttonTitle, for: .normal)
        paymentMethodButton.setImage(self.buttonImage, for: .normal)
        paymentMethodButton.setTitleColor(buttonTitleColor, for: .normal)
        paymentMethodButton.tintColor = buttonTintColor
        paymentMethodButton.layer.borderWidth = buttonBorderWidth
        paymentMethodButton.layer.borderColor = buttonBorderColor?.cgColor
        paymentMethodButton.addTarget(self, action: #selector(paymentMethodButtonTapped(_:)), for: .touchUpInside)
        return paymentMethodButton
    }
    
    lazy var submitButton: PrimerButton? = {
        var buttonTitle: String = ""
        
        switch self.paymentMethodTokenizationViewModel.config.type {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            switch Primer.shared.intent {
            case .checkout:
                let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
                buttonTitle = Strings.PaymentButton.pay
                
            case .vault:
                buttonTitle = Strings.PrimerCardFormView.addCardButtonTitle
                
            case .none:
                assert(true, "Intent should have been set")
            }
            
            let submitButton = PrimerButton()
            submitButton.translatesAutoresizingMaskIntoConstraints = false
            submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            submitButton.isAccessibilityElement = true
            submitButton.accessibilityIdentifier = "submit_btn"
            submitButton.isEnabled = false
            submitButton.setTitle(buttonTitle, for: .normal)
            submitButton.setTitleColor(theme.mainButton.text.color, for: .normal)
            submitButton.backgroundColor = theme.mainButton.color(for: .disabled)
            submitButton.layer.cornerRadius = 4
            submitButton.clipsToBounds = true
            submitButton.addTarget(self, action: #selector(submitButtonTapped(_:)), for: .touchUpInside)
            return submitButton
            
        case PrimerPaymentMethodType.primerTestKlarna.rawValue,
            PrimerPaymentMethodType.primerTestPayPal.rawValue,
            PrimerPaymentMethodType.primerTestSofort.rawValue:
            let submitButton = PrimerButton()
            submitButton.translatesAutoresizingMaskIntoConstraints = false
            submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            submitButton.isAccessibilityElement = true
            submitButton.accessibilityIdentifier = "submit_btn"
            submitButton.isEnabled = false
            submitButton.setTitleColor(theme.mainButton.text.color, for: .normal)
            submitButton.backgroundColor = theme.mainButton.color(for: .disabled)
            submitButton.layer.cornerRadius = 4
            submitButton.clipsToBounds = true
            submitButton.addTarget(self, action: #selector(submitButtonTapped(_:)), for: .touchUpInside)
            return submitButton
            
        case PrimerPaymentMethodType.adyenBlik.rawValue,
            PrimerPaymentMethodType.xfersPayNow.rawValue:
            let btn = PrimerButton()
            btn.isEnabled = false
            btn.clipsToBounds = true
            btn.heightAnchor.constraint(equalToConstant: 45).isActive = true
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            btn.layer.cornerRadius = 4
            btn.backgroundColor = btn.isEnabled ? theme.mainButton.color(for: .enabled) : theme.mainButton.color(for: .disabled)
            btn.setTitleColor(.white, for: .normal)
            btn.addTarget(self, action: #selector(submitButtonTapped(_:)), for: .touchUpInside)
            btn.setTitle("Confirm", for: .normal)
            return btn
            
        default:
            return nil
        }
    }()
    
    // MARK: - INITIALIZATION
    
    required init(paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol) {
        self.paymentMethodTokenizationViewModel = paymentMethodTokenizationViewModel
    }
    
    // MARK: - HELPERS
    
    func makeLogoImageView(withSize size: CGSize?) -> UIImageView? {
        guard let logo = self.logo else { return nil }
        
        var tmpSize: CGSize! = size
        if size == nil {
            tmpSize = CGSize(width: logo.size.width, height: logo.size.height)
        }
        
        let imgView = UIImageView()
        imgView.image = logo
        imgView.contentMode = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.heightAnchor.constraint(equalToConstant: tmpSize.width).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: tmpSize.height).isActive = true
        return imgView
    }
    
    func makeIconImageView(withDimension dimension: CGFloat) -> UIImageView? {
        guard let squareLogo = self.icon else { return nil }
        let imgView = UIImageView()
        imgView.image = squareLogo
        imgView.contentMode = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.heightAnchor.constraint(equalToConstant: dimension).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: dimension).isActive = true
        return imgView
    }
    
    @IBAction func paymentMethodButtonTapped(_ sender: UIButton) {
        self.paymentMethodTokenizationViewModel.start()
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        self.paymentMethodTokenizationViewModel.submitButtonTapped()
    }
}

#endif
