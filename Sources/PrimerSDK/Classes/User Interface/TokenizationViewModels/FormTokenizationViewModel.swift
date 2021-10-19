//
//  FormTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 11/10/21.
//

import Foundation

class FormPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    private var flow: PaymentFlow
    private var cardComponentsManager: CardComponentsManager!
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
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
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
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
        cardComponentsManager.tokenize()
    }
}

extension FormPaymentMethodTokenizationViewModel: CardComponentsManagerDelegate {
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethod: PaymentMethod) {
        self.paymentMethod = paymentMethod
        
        DispatchQueue.main.async {
            if Primer.shared.flow.internalSessionFlow.vaulted {
                Primer.shared.delegate?.tokenAddedToVault?(paymentMethod)
            }
            
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, resumeHandler: self)
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, { err in
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
        if let decodedClientToken = ClientTokenService.decodedClientToken {
            completion(decodedClientToken.accessToken, nil)
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

extension FormPaymentMethodTokenizationViewModel: PrimerTextFieldViewDelegate {
    
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
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork) {
        
    }
    
}

extension FormPaymentMethodTokenizationViewModel {
    
    override func handle(error: Error) {
        DispatchQueue.main.async {
            self.submitButton.showSpinner(false)
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        }
        completion?(nil, error)
    }
    
    override func handle(newClientToken clientToken: String) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        if state.clientToken == clientToken {
            let err = PrimerError.invalidValue(key: "clientToken")
            Primer.shared.delegate?.onResumeError?(err)
            handle(error: err)
            return
        }
        
        do {
            try ClientTokenService.storeClientToken(clientToken)
                       
            guard let paymentMethod = paymentMethod else {
                let err = PrimerError.invalidValue(key: "paymentMethod")
                Primer.shared.delegate?.onResumeError?(err)
                handle(error: err)
                return
            }
            
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.clientTokenNull
                Primer.shared.delegate?.onResumeError?(err)
                handle(error: err)
                return
            }
           
            if decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
                #if canImport(Primer3DS)
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(paymentMethod: paymentMethod, protocolVersion: decodedClientToken.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                    switch result {
                    case .success(let res):
                        guard let threeDSPostAuthResponse = res.1,
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
