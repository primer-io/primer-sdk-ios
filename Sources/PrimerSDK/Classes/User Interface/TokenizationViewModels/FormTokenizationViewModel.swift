//
//  FormTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 11/10/21.
//

#if canImport(UIKit)

import Foundation
import UIKit

class CardFormPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    private var flow: PaymentFlow
    private var cardComponentsManager: CardComponentsManager!
    
    override lazy var hasNativeUI: Bool = {
        switch config.type {
        case .paymentCard:
            return true
        default:
            assert(true, "Shouldn't end up in here")
            return false
        }
    }()
    
    override lazy var title: String = {
        return "Payment Card"
    }()
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        case .paymentCard:
            return Primer.shared.flow.internalSessionFlow.vaulted
                ? NSLocalizedString("payment-method-type-card-vaulted",
                                    tableName: nil,
                                    bundle: Bundle.primerResources,
                                    value: "Add new card",
                                    comment: "Add new card - Payment Method Type (Card Vaulted)")

                : NSLocalizedString("payment-method-type-card-not-vaulted",
                                    tableName: nil,
                                    bundle: Bundle.primerResources,
                                    value: "Pay with card",
                                    comment: "Pay with card - Payment Method Type (Card Not vaulted)")
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
        switch config.type {
        case .paymentCard:
            return UIImage(named: "creditCard", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonColor: UIColor? = {
        switch config.type {
        case .paymentCard:
            return .white
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .paymentCard:
            return .black
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .paymentCard:
            return 1.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .paymentCard:
            return .black
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .paymentCard:
            return .black
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    override lazy var buttonCornerRadius: CGFloat? = {
        return 4.0
    }()
    
    lazy var cardNumberField: PrimerCardNumberFieldView = {
        let cardNumberField = PrimerCardNumberFieldView()
        cardNumberField.placeholder = "4242 4242 4242 4242"
        cardNumberField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardNumberField.textColor = theme.colorTheme.text1
        cardNumberField.borderStyle = .none
        cardNumberField.delegate = self
        return cardNumberField
    }()
    
    lazy var expiryDateField: PrimerExpiryDateFieldView = {
        let expiryDateField = PrimerExpiryDateFieldView()
        expiryDateField.placeholder = "02/22"
        expiryDateField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        expiryDateField.textColor = theme.colorTheme.text1
        expiryDateField.delegate = self
        return expiryDateField
    }()
    
    lazy var cvvField: PrimerCVVFieldView = {
        let cvvField = PrimerCVVFieldView()
        cvvField.placeholder = "123"
        cvvField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cvvField.textColor = theme.colorTheme.text1
        cvvField.delegate = self
        return cvvField
    }()
    
    lazy var cardholderNameField: PrimerCardholderNameFieldView = {
        let cardholderNameField = PrimerCardholderNameFieldView()
        cardholderNameField.placeholder = "John Smith"
        cardholderNameField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardholderNameField.textColor = theme.colorTheme.text1
        cardholderNameField.delegate = self
        return cardholderNameField
    }()
    
    internal lazy var cardNumberContainerView: PrimerCustomFieldView = {
        let cardNumberContainerView = PrimerCustomFieldView()
        cardNumberContainerView.fieldView = cardNumberField
        cardNumberContainerView.placeholderText = "Card number"
        cardNumberContainerView.setup()
        cardNumberContainerView.tintColor = theme.colorTheme.tint1
        return cardNumberContainerView
    }()
    internal lazy var expiryDateContainerView: PrimerCustomFieldView = {
        let expiryDateContainerView = PrimerCustomFieldView()
        expiryDateContainerView.fieldView = expiryDateField
        expiryDateContainerView.placeholderText = "Expiry"
        expiryDateContainerView.setup()
        expiryDateContainerView.tintColor = theme.colorTheme.tint1
        return expiryDateContainerView
    }()
    internal lazy var cvvContainerView: PrimerCustomFieldView = {
        let cvvContainerView = PrimerCustomFieldView()
        cvvContainerView.fieldView = cvvField
        cvvContainerView.placeholderText = "CVV/CVC"
        cvvContainerView.setup()
        cvvContainerView.tintColor = theme.colorTheme.tint1
        return cvvContainerView
    }()
    internal lazy var cardholderNameContainerView: PrimerCustomFieldView = {
        let cardholderNameContainerView = PrimerCustomFieldView()
        cardholderNameContainerView.fieldView = cardholderNameField
        cardholderNameContainerView.placeholderText = "Name"
        cardholderNameContainerView.setup()
        cardholderNameContainerView.tintColor = theme.colorTheme.tint1
        return cardholderNameContainerView
    }()
    
    lazy var submitButton: PrimerOldButton = {
        var buttonTitle: String = ""
        if flow == .checkout {
            let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
            buttonTitle = NSLocalizedString("primer-form-view-card-submit-button-text-checkout",
                                            tableName: nil,
                                            bundle: Bundle.primerResources,
                                            value: "Pay",
                                            comment: "Pay - Card Form View (Sumbit button text)") + " " + (viewModel.amountStringed ?? "")
        } else if flow == .vault {
            buttonTitle = NSLocalizedString("primer-card-form-add-card",
                                            tableName: nil,
                                            bundle: Bundle.primerResources,
                                            value: "Add card",
                                            comment: "Add card - Card Form (Vault title text)")
        }
        
        let submitButton = PrimerOldButton()
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        submitButton.isAccessibilityElement = true
        submitButton.accessibilityIdentifier = "submit_btn"
        submitButton.isEnabled = false
        submitButton.setTitle(buttonTitle, for: .normal)
        submitButton.setTitleColor(theme.colorTheme.text2, for: .normal)
        submitButton.backgroundColor = theme.colorTheme.disabled1
        submitButton.layer.cornerRadius = 4
        submitButton.clipsToBounds = true
        submitButton.addTarget(self, action: #selector(payButtonTapped(_:)), for: .touchUpInside)
        return submitButton
    }()
    
    required init(config: PaymentMethodConfig) {
        self.flow = Primer.shared.flow.internalSessionFlow.vaulted ? .vault : .checkout
        super.init(config: config)
        
        self.cardComponentsManager = CardComponentsManager(
            flow: flow,
            cardnumberField: cardNumberField,
            expiryDateField: expiryDateField,
            cvvField: cvvField,
            cardholderNameField: cardholderNameField)
        cardComponentsManager.delegate = self
    }
    
    override func validate() throws {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = state.decodedClientToken, decodedClientToken.isValid else {
            let err = PaymentException.missingClientToken
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.tokenizationPreRequestFailed
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        if !Primer.shared.flow.internalSessionFlow.vaulted {
            if settings.amount == nil {
                let err = PaymentException.missingAmount
                _ = ErrorHandler.shared.handle(error: err)
                throw err
            }
            
            if settings.currency == nil {
                let err = PaymentException.missingCurrency
                _ = ErrorHandler.shared.handle(error: err)
                throw err
            }
        }
    }
    
    @objc
    override func presentNativeUI() {
        let cfvc = PrimerCardFormViewController(viewModel: self)
        Primer.shared.primerRootVC?.show(viewController: cfvc)
    }
    
    @objc
    override func startTokenizationFlow() {
        super.startTokenizationFlow()
        
        do {
            try validate()
        } catch {
            DispatchQueue.main.async {
                Primer.shared.delegate?.checkoutFailed?(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        DispatchQueue.main.async {
            let pcfvc = PrimerCardFormViewController(viewModel: self)
            Primer.shared.primerRootVC?.show(viewController: pcfvc)
        }
    }
    
    @objc
    func payButtonTapped(_ sender: UIButton) {
        startTokenizationFlow()
    }
}

extension CardFormPaymentMethodTokenizationViewModel: CardComponentsManagerDelegate {
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethodToken: PaymentMethodToken) {
        self.paymentMethod = paymentMethodToken
        
        DispatchQueue.main.async {
            self.paymentMethod = paymentMethodToken
            
            if Primer.shared.flow.internalSessionFlow.vaulted {
                Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
            }
            
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: self)
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, { err in
                self.cardComponentsManager.setIsLoading(false)
                
                if let err = err {
                    self.handleFailedTokenizationFlow(error: err)
                } else {
                    self.handleSuccessfulTokenizationFlow()
                }
            })
        }
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, clientTokenCallback completion: @escaping (String?, Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if let clientToken = state.accessToken {
            completion(clientToken, nil)
        } else {
            completion(nil, PrimerError.clientTokenNull)
        }
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, tokenizationFailedWith errors: [Error]) {
        submitButton.showSpinner(false)
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, isLoading: Bool) {
        submitButton.showSpinner(isLoading)
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = !isLoading
    }
    
}

extension CardFormPaymentMethodTokenizationViewModel: PrimerTextFieldViewDelegate {
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        if primerTextFieldView is PrimerCardNumberFieldView {
            cardNumberContainerView.errorText = nil
        } else if primerTextFieldView is PrimerExpiryDateFieldView {
            expiryDateContainerView.errorText = nil
        } else if primerTextFieldView is PrimerCVVFieldView {
            cvvContainerView.errorText = nil
        } else if primerTextFieldView is PrimerCardholderNameFieldView {
            cardholderNameContainerView.errorText = nil
        }
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        if primerTextFieldView is PrimerCardNumberFieldView, isValid == false {
            cardNumberContainerView.errorText = "Invalid card number"
        } else if primerTextFieldView is PrimerExpiryDateFieldView, isValid == false {
            expiryDateContainerView.errorText = "Invalid date"
        } else if primerTextFieldView is PrimerCVVFieldView, isValid == false {
            cvvContainerView.errorText = "Invalid CVV"
        } else if primerTextFieldView is PrimerCardholderNameFieldView, isValid == false {
            cardholderNameContainerView.errorText = "Invalid name"
        }

        if cardNumberField.isTextValid,
           expiryDateField.isTextValid,
           cvvField.isTextValid,
           cardholderNameField.isTextValid
        {
            submitButton.isEnabled = true
            submitButton.backgroundColor = theme.colorTheme.main2
        } else {
            submitButton.isEnabled = false
            submitButton.backgroundColor = theme.colorTheme.disabled1
        }
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error) {

    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork?) {
        if cardNumberContainerView.rightImage2 == nil && cardNetwork?.icon != nil {
            cardNumberContainerView.rightImage2 = cardNetwork?.icon
            
            var surchargeStr: String = ""
            if flow == .checkout, let surcharge = cardNetwork?.surcharge {
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                surchargeStr = " + " + surcharge.toCurrencyString(currency: settings.currency!)
            }
            
            let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
            let title = NSLocalizedString("primer-form-view-card-submit-button-text-checkout",
                                            tableName: nil,
                                            bundle: Bundle.primerResources,
                                            value: "Pay",
                                            comment: "Pay - Card Form View (Sumbit button text)") + " " + (viewModel.amountStringed ?? "") + surchargeStr
            submitButton.setTitle(title, for: .normal)
            
        } else if cardNumberContainerView.rightImage2 != nil && cardNetwork?.icon == nil {
            cardNumberContainerView.rightImage2 = nil
        }
    }
    
}

extension CardFormPaymentMethodTokenizationViewModel {
    
    override func handle(error: Error) {
        DispatchQueue.main.async {4
            self.submitButton.showSpinner(false)
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        }
        completion?(nil, error)
    }
    
    override func handle(newClientToken clientToken: String) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        if state.accessToken == clientToken {
            let err = PrimerError.invalidValue(key: "clientToken")
            Primer.shared.delegate?.onResumeError?(err)
            handle(error: err)
            return
        }
        
        do {
            try ClientTokenService.storeClientToken(clientToken)
           
            let state: AppStateProtocol = DependencyContainer.resolve()
            let decodedClientToken = state.decodedClientToken!
            
            guard let paymentMethod = paymentMethod else {
                let err = PrimerError.invalidValue(key: "paymentMethod")
                Primer.shared.delegate?.onResumeError?(err)
                handle(error: err)
                return
            }
           
            if decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
                #if canImport(Primer3DS)
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(paymentMethodToken: paymentMethod, protocolVersion: state.decodedClientToken?.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        guard let threeDSPostAuthResponse = paymentMethodToken.1,
                              let resumeToken = threeDSPostAuthResponse.resumeToken else {
                            let err = PrimerError.threeDSFailed
                            Primer.shared.delegate?.onResumeError?(err)
                            return
                        }
                       
                        Primer.shared.delegate?.onResumeSuccess?(resumeToken, resumeHandler: self)
                       
                    case .failure(let err):
                        log(logLevel: .error, message: "Failed to perform 3DS with error \(err as NSError)")
                        let err = PrimerError.threeDSFailed
                        Primer.shared.delegate?.onResumeError?(err)
                    }
                }
                #else
                let error = PrimerError.threeDSFailed
                Primer.shared.delegate?.onResumeError?(error)
                #endif
               
            } else {
                let err = PrimerError.invalidValue(key: "resumeToken")
                Primer.shared.delegate?.onResumeError?(err)
                handle(error: err)
            }
           
        } catch {
            Primer.shared.delegate?.onResumeError?(error)
            handle(error: error)
        }
    }
    
    override func handleSuccess() {
        DispatchQueue.main.async {
            self.submitButton.showSpinner(false)
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        }
        completion?(paymentMethod, nil)
    }
}

#endif
