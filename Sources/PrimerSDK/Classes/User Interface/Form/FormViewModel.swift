//
//  FormViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 14/02/2021.

#if canImport(UIKit)

import Foundation

internal protocol FormViewModelProtocol {
    func loadConfig(_ completion: @escaping (Error?) -> Void)
    var popOnComplete: Bool { get }
    var mandate: DirectDebitMandate { get }
    func getSubmitButtonTitle(formType: FormType) -> String
    func setState(_ value: String?, type: FormTextFieldType)
    func onSubmit(formType: FormType)
    #if canImport(CardScan)
    func onBottomLinkTapped(delegate: CardScannerViewControllerDelegate)
    #endif
    func submit()
    func onReturnButtonTapped()
}

internal class FormViewModel: FormViewModelProtocol {
    
    private var resumeHandler: ResumeHandlerProtocol!
    private var paymentMethod: PaymentMethodToken!
    
    var popOnComplete: Bool {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.directDebitFormCompleted
    }

    var mandate: DirectDebitMandate {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.directDebitMandate
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init() {
        resumeHandler = self
    }
    
    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        if state.decodedClientToken.exists {
            let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            paymentMethodConfigService.fetchConfig(completion)
        } else {
            let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
            clientTokenService.loadCheckoutConfig { (err) in
                if let err = err {
                    completion(err)
                } else {
                    let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                    paymentMethodConfigService.fetchConfig(completion)
                }
            }
        }
    }

    func getSubmitButtonTitle(formType: FormType) -> String {
        switch formType {
        case .cardForm:
            if Primer.shared.flow.internalSessionFlow.vaulted {
                return NSLocalizedString("primer-form-view-card-submit-button-text-vault",
                                         tableName: nil,
                                         bundle: Bundle.primerResources,
                                         value: "Add card",
                                         comment: "Add card - Card Form View (Sumbit button text)")
            } else {
                return NSLocalizedString("primer-form-view-card-submit-button-text-checkout",
                                         tableName: nil,
                                         bundle: Bundle.primerResources,
                                         value: "Pay",
                                         comment: "Pay - Card Form View (Sumbit button text)")
            }
            

        default:
            return NSLocalizedString("primer-form-view-submit-button-text",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Next",
                                     comment: "Next - Form View (Sumbit button text)")
        }
    }

    func setState(_ value: String?, type: FormTextFieldType) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        switch type {
        case .iban: state.directDebitMandate.iban = value?.withoutWhiteSpace
        case .accountNumber: state.directDebitMandate.accountNumber = value
        case .addressLine1: state.directDebitMandate.address?.addressLine1 = value
        case .addressLine2: state.directDebitMandate.address?.addressLine2 = value
        case .city: state.directDebitMandate.address?.city = value
        case .country: state.directDebitMandate.address?.countryCode = value
        case .email: state.directDebitMandate.email = value
        case .firstName: state.directDebitMandate.firstName = value
        case .lastName: state.directDebitMandate.lastName = value
        case .postalCode: state.directDebitMandate.address?.postalCode = value
        case .sortCode: state.directDebitMandate.sortCode = value
        case .cardholderName: state.cardData.name = value ?? ""
        case .cardNumber: state.cardData.number = value?.withoutWhiteSpace ?? ""
        case .expiryDate:
            guard let expiryValues = value?.split(separator: "/") else { return }
            let expMonth = "\(expiryValues[0])"
            let expYear = "20\(expiryValues[1])"
            state.cardData.expiryYear = expYear
            state.cardData.expiryMonth = expMonth
        case .cvc: state.cardData.cvc = value ?? ""
        }
    }

    func onSubmit(formType: FormType) {
        let router: RouterDelegate = DependencyContainer.resolve()
        
        if popOnComplete { return router.pop() }

        switch formType {
        case .iban:
            router.show(.confirmMandate)
        case .bankAccount:
            router.show(.form(type: .name(mandate: mandate)))
        case .name:
            router.show(.form(type: .email(mandate: mandate)))
        case .email:
            router.show(.form(type: .address(mandate: mandate)))
        case .address:
            router.popAllAndShow(.confirmMandate)
        case .cardForm:
            submit()
        }
    }

    #if canImport(CardScan)
    func onBottomLinkTapped(delegate: CardScannerViewControllerDelegate) {
        router.show(.cardScanner(delegate: delegate))
    }
    #endif

    func onReturnButtonTapped() {
        let router: RouterDelegate = DependencyContainer.resolve()
        router.pop()
    }

    func submit() {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        let instrument = PaymentInstrument(
            number: state.cardData.number,
            cvv: state.cardData.cvc,
            expirationMonth: state.cardData.expiryMonth,
            expirationYear: state.cardData.expiryYear,
            cardholderName: state.cardData.name
        )
        let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
        
        let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
        tokenizationService.tokenize(request: request) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .failure(let error):
                    _ = ErrorHandler.shared.handle(error: error)
                    Primer.shared.delegate?.checkoutFailed?(with: error)
                    Primer.shared.delegate?.onResumeError?(error, resumeHandler: self)
                    
                case .success(let token):
                    self.paymentMethod = token
                    
                    switch Primer.shared.flow.internalSessionFlow {
                    case .checkout,
                         .checkoutWithCard,
                         .checkoutWithKlarna:
                        Primer.shared.delegate?.authorizePayment?(token, { err in
                            
                        })
                        
                    default:
                        break
                    }
                    
                    Primer.shared.delegate?.onTokenizeSuccess?(token, resumeHandler: self)
                    Primer.shared.delegate?.onTokenizeSuccess?(token, { err in
                        DispatchQueue.main.async {
                            let router: RouterDelegate = DependencyContainer.resolve()
                            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

                            if settings.hasDisabledSuccessScreen {
                                Primer.shared.dismiss()
                            } else if let err = err {
                                router.show(.error(error: err))
                            } else {
                                router.show(.success(type: .regular))
                            }
                        }
                    })
                }
            }
        }
    }
}

extension FormViewModel: ResumeHandlerProtocol {
    func handle(error: Error) {
        DispatchQueue.main.async {
            let router: RouterDelegate = DependencyContainer.resolve()
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                router.show(.error(error: PrimerError.generic))
            }
        }
    }
    
    func handle(newClientToken clientToken: String) {
        do {
            try ClientTokenService.storeClientToken(clientToken)
            
            let state: AppStateProtocol = DependencyContainer.resolve()
            let decodedClientToken = state.decodedClientToken!
            
            if decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue, let paymentMethod = paymentMethod {
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(paymentMethodToken: paymentMethod, protocolVersion: state.decodedClientToken?.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        guard let threeDSPostAuthResponse = paymentMethodToken.1,
                              let resumeToken = threeDSPostAuthResponse.resumeToken else {
                            Primer.shared.delegate?.onResumeError?(PrimerError.threeDSFailed, resumeHandler: self)
                            return
                        }
                        
                        Primer.shared.delegate?.onResumeSuccess?(resumeToken, resumeHandler: self)
                        
                    case .failure(let err):
                        log(logLevel: .error, message: "Failed to perform 3DS with error \(err as NSError)")
                        Primer.shared.delegate?.onResumeError?(PrimerError.threeDSFailed, resumeHandler: self)
                    }
                }
                
            } else {
                Primer.shared.delegate?.onResumeSuccess?(clientToken, resumeHandler: self)
            }
            
        } catch {
            Primer.shared.delegate?.onResumeError?(error, resumeHandler: self)
        }
    }
    
    func handleSuccess() {
        DispatchQueue.main.async {
            let router: RouterDelegate = DependencyContainer.resolve()
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                router.show(.success(type: .regular))
            }
        }
    }
}

#endif
