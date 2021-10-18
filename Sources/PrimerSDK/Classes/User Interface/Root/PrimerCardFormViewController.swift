//
//  PrimerCardFormViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/7/21.
//

import UIKit

/// Subclass of the PrimerFormViewController that uses the checkout components and the card components manager
class PrimerCardFormViewController: PrimerFormViewController {
    
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private var cardComponentsManager: CardComponentsManager!
    private var flow: PaymentFlow!
    private var resumeHandler: ResumeHandlerProtocol!
    
    private let cardNumberContainerView = PrimerCustomFieldView()
    private let cardNumberField = PrimerCardNumberFieldView()
    private let expiryDateContainerView = PrimerCustomFieldView()
    private let expiryDateField = PrimerExpiryDateFieldView()
    private let cvvContainerView = PrimerCustomFieldView()
    private let cvvField = PrimerCVVFieldView()
    private let cardholderNameContainerView = PrimerCustomFieldView()
    private let cardholderNameField = PrimerCardholderNameFieldView()
    private let submitButton = PrimerButton()
    private var paymentMethod: PaymentMethodToken?
    
    init(flow: PaymentFlow) {
        self.flow = flow
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        title = NSLocalizedString("primer-form-type-main-title-card-form",
                                  tableName: nil,
                                  bundle: Bundle.primerResources,
                                  value: "Enter your card details",
                                  comment: "Enter your card details - Form Type Main Title (Card)")

        view.backgroundColor = theme.colorTheme.main1
        
        verticalStackView.spacing = 6
        
        cardNumberField.placeholder = "4242 4242 4242 4242"
        cardNumberField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardNumberField.textColor = theme.colorTheme.text1
        cardNumberField.borderStyle = .none
        cardNumberField.delegate = self
        
        cardNumberContainerView.fieldView = cardNumberField
        cardNumberContainerView.placeholderText = "Card number"
        cardNumberContainerView.setup()
        cardNumberContainerView.tintColor = theme.colorTheme.tint1
        verticalStackView.addArrangedSubview(cardNumberContainerView)

        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .fill
        horizontalStackView.distribution = .fillEqually
        
        expiryDateField.placeholder = "02/22"
        expiryDateField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        expiryDateField.textColor = theme.colorTheme.text1
        expiryDateField.delegate = self
        
        expiryDateContainerView.fieldView = expiryDateField
        expiryDateContainerView.placeholderText = "Expiry"
        expiryDateContainerView.setup()
        expiryDateContainerView.tintColor = theme.colorTheme.tint1
        horizontalStackView.addArrangedSubview(expiryDateContainerView)
        
        cvvField.placeholder = "123"
        cvvField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cvvField.textColor = theme.colorTheme.text1
        cvvField.delegate = self
        
        cvvContainerView.fieldView = cvvField
        cvvContainerView.placeholderText = "CVV/CVC"
        cvvContainerView.setup()
        cvvContainerView.tintColor = theme.colorTheme.tint1
        horizontalStackView.addArrangedSubview(cvvContainerView)
        horizontalStackView.spacing = 16
        verticalStackView.addArrangedSubview(horizontalStackView)
        
        cardholderNameField.placeholder = "John Smith"
        cardholderNameField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardholderNameField.textColor = theme.colorTheme.text1
        cardholderNameField.delegate = self
        
        cardholderNameContainerView.fieldView = cardholderNameField
        cardholderNameContainerView.placeholderText = "Name"
        cardholderNameContainerView.setup()
        cardholderNameContainerView.tintColor = theme.colorTheme.tint1
        verticalStackView.addArrangedSubview(cardholderNameContainerView)
        
        if flow == .checkout {
            let saveCardSwitchContainerStackView = UIStackView()
            saveCardSwitchContainerStackView.axis = .horizontal
            saveCardSwitchContainerStackView.alignment = .fill
            saveCardSwitchContainerStackView.spacing = 8.0
            
            let saveCardSwitch = UISwitch()
            saveCardSwitchContainerStackView.addArrangedSubview(saveCardSwitch)
            
            let saveCardLabel = UILabel()
            saveCardLabel.text = "Save this card"
            saveCardLabel.textColor = theme.colorTheme.text1
            saveCardLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
            saveCardSwitchContainerStackView.addArrangedSubview(saveCardLabel)
            
            verticalStackView.addArrangedSubview(saveCardSwitchContainerStackView)
            saveCardSwitchContainerStackView.isHidden = true
        }
        
        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        verticalStackView.addArrangedSubview(separatorView)
        
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
        verticalStackView.addArrangedSubview(submitButton)
        
        cardComponentsManager = CardComponentsManager(
//            clientToken: state.accessToken,
            flow: flow,
            cardnumberField: cardNumberField,
            expiryDateField: expiryDateField,
            cvvField: cvvField,
            cardholderNameField: cardholderNameField)
        cardComponentsManager.delegate = self        
    }
    
    @objc func payButtonTapped(_ sender: UIButton) {
        cardComponentsManager.tokenize()
    }
    
}

extension PrimerCardFormViewController: CardComponentsManagerDelegate, PrimerTextFieldViewDelegate {
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethodToken: PaymentMethodToken) {
        self.paymentMethod = paymentMethodToken
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            if Primer.shared.flow.internalSessionFlow.vaulted {
                Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
            }
            
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: strongSelf)
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, { err in
                self?.cardComponentsManager.setIsLoading(false)
                
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                
                if let err = err {
                    if settings.hasDisabledSuccessScreen {
                        Primer.shared.dismiss()
                    } else {
                        let evc = ErrorViewController(message: err.localizedDescription)
                        evc.view.translatesAutoresizingMaskIntoConstraints = false
                        evc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                        Primer.shared.primerRootVC?.show(viewController: evc)
                    }
                } else {
                    if settings.hasDisabledSuccessScreen {
                        Primer.shared.dismiss()
                    } else {
                        let svc = SuccessViewController()
                        svc.view.translatesAutoresizingMaskIntoConstraints = false
                        svc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                        Primer.shared.primerRootVC?.show(viewController: svc)
                    }
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
        DispatchQueue.main.async {
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
            
            let err = PrimerError.containerError(errors: errors)
            Primer.shared.delegate?.checkoutFailed?(with: err)
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                let evc = ErrorViewController(message: err.localizedDescription)
                evc.view.translatesAutoresizingMaskIntoConstraints = false
                evc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                Primer.shared.primerRootVC?.show(viewController: evc)
            }
        }
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, isLoading: Bool) {
        submitButton.showSpinner(isLoading)
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = !isLoading
    }
    
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
        if isValid == false && !primerTextFieldView.isEmpty {
            if primerTextFieldView is PrimerCardNumberFieldView {
                cardNumberContainerView.errorText = "Invalid card number"
                cardNumberContainerView.rightImage1 = UIImage(
                    named: "error",
                    in: Bundle.primerResources,
                    compatibleWith: nil)?
                    .withRenderingMode(.alwaysTemplate)

                cardNumberContainerView.rightImage1TintColor = theme.colorTheme.error1
                
            } else if primerTextFieldView is PrimerExpiryDateFieldView {
                expiryDateContainerView.errorText = "Invalid date"
                expiryDateContainerView.rightImage1 = UIImage(
                    named: "error",
                    in: Bundle.primerResources,
                    compatibleWith: nil)?
                    .withRenderingMode(.alwaysTemplate)

                expiryDateContainerView.rightImage1TintColor = theme.colorTheme.error1
                
            } else if primerTextFieldView is PrimerCVVFieldView {
                cvvContainerView.errorText = "Invalid CVV"
                cvvContainerView.rightImage1 = UIImage(
                    named: "error",
                    in: Bundle.primerResources,
                    compatibleWith: nil)?
                    .withRenderingMode(.alwaysTemplate)

                cvvContainerView.rightImage1TintColor = theme.colorTheme.error1
                
            } else if primerTextFieldView is PrimerCardholderNameFieldView {
                cardholderNameContainerView.errorText = "Invalid name"
                cardholderNameContainerView.rightImage1 = UIImage(
                    named: "error",
                    in: Bundle.primerResources,
                    compatibleWith: nil)?
                    .withRenderingMode(.alwaysTemplate)

                cardholderNameContainerView.rightImage1TintColor = theme.colorTheme.error1
            }
        } else if isValid == true {
            if primerTextFieldView is PrimerCardNumberFieldView {
                cardNumberContainerView.errorText = nil
                cardNumberContainerView.rightImage1 = UIImage(
                    named: "check2",
                    in: Bundle.primerResources,
                    compatibleWith: nil)?
                    .withRenderingMode(.alwaysTemplate)

                cardNumberContainerView.rightImage1TintColor = theme.colorTheme.success1
                
            } else if primerTextFieldView is PrimerExpiryDateFieldView {
                expiryDateContainerView.errorText = nil
                expiryDateContainerView.rightImage1 = UIImage(
                    named: "check2",
                    in: Bundle.primerResources,
                    compatibleWith: nil)?
                    .withRenderingMode(.alwaysTemplate)

                expiryDateContainerView.rightImage1TintColor = theme.colorTheme.success1
                
            } else if primerTextFieldView is PrimerCVVFieldView {
                cvvContainerView.errorText = nil
                cvvContainerView.rightImage1 = UIImage(
                    named: "check2",
                    in: Bundle.primerResources,
                    compatibleWith: nil)?
                    .withRenderingMode(.alwaysTemplate)

                cvvContainerView.rightImage1TintColor = theme.colorTheme.success1
                
            } else if primerTextFieldView is PrimerCardholderNameFieldView {
                cardholderNameContainerView.errorText = nil
                cardholderNameContainerView.rightImage1 = UIImage(
                    named: "check2",
                    in: Bundle.primerResources,
                    compatibleWith: nil)?
                    .withRenderingMode(.alwaysTemplate)

                cardholderNameContainerView.rightImage1TintColor = theme.colorTheme.success1
            }
        } else {
            if primerTextFieldView is PrimerCardNumberFieldView {
                cardNumberContainerView.errorText = nil
                cardNumberContainerView.rightImage1 = nil
                cardNumberContainerView.rightImage1TintColor = nil
                
            } else if primerTextFieldView is PrimerExpiryDateFieldView {
                expiryDateContainerView.errorText = nil
                expiryDateContainerView.rightImage1 = nil
                expiryDateContainerView.rightImage1TintColor = nil
                
            } else if primerTextFieldView is PrimerCVVFieldView {
                cvvContainerView.errorText = nil
                cvvContainerView.rightImage1 = nil
                cvvContainerView.rightImage1TintColor = nil
                
            } else if primerTextFieldView is PrimerCardholderNameFieldView {
                cardholderNameContainerView.errorText = nil
                cardholderNameContainerView.rightImage1 = nil
                cardholderNameContainerView.rightImage1TintColor = nil
            }
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
        cardNumberContainerView.rightImage2 = cardNetwork?.icon
    }
    
}

extension PrimerCardFormViewController: ResumeHandlerProtocol {
    func handle(error: Error) {
        DispatchQueue.main.async {
            self.cardComponentsManager.setIsLoading(false)
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                let evc = ErrorViewController(message: error.localizedDescription)
                evc.view.translatesAutoresizingMaskIntoConstraints = false
                evc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: evc)
            }
        }
    }
    
    func handle(newClientToken clientToken: String) {
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
                            self.handle(error: err)
                            return
                        }
                       
                        Primer.shared.delegate?.onResumeSuccess?(resumeToken, resumeHandler: self)
                       
                    case .failure(let err):
                        log(logLevel: .error, message: "Failed to perform 3DS with error \(err as NSError)")
                        let err = PrimerError.threeDSFailed
                        Primer.shared.delegate?.onResumeError?(err)
                        self.handle(error: err)
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
    
    func handleSuccess() {
        DispatchQueue.main.async {
            self.cardComponentsManager.setIsLoading(false)
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                let svc = SuccessViewController()
                svc.view.translatesAutoresizingMaskIntoConstraints = false
                svc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: svc)
            }
        }
    }
}
