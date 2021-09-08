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
    func submit(completion: @escaping (PrimerError?) -> Void)
    func onReturnButtonTapped()
}

internal class FormViewModel: FormViewModelProtocol {
    
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
            submit { error in
                DispatchQueue.main.async { [weak self] in
                    if let error = error {
                        router.show(.error(error: error))
                    } else {
                        router.show(.success(type: .regular))
                    }
                }
            }
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

    func submit(completion: @escaping (PrimerError?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        let instrument = PaymentMethod.Card.Details(number: state.cardData.number,
                                                    cvv: state.cardData.cvc,
                                                    expirationMonth: state.cardData.expiryMonth,
                                                    expirationYear: state.cardData.expiryYear,
                                                    cardholderName: state.cardData.name)
        
        let request = PaymentInstrumentizationRequest(paymentInstrument: instrument, state: state)
        
        let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
        tokenizationService.tokenize(request: request) { [weak self] result in
            switch result {
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(error)
            case .success(let token):
                switch Primer.shared.flow.internalSessionFlow {
                case .checkout,
                     .checkoutWithCard,
                     .checkoutWithKlarna:
                    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                    settings.authorizePayment(token, { error in
                        if error.exists {
                            completion(PrimerError.tokenizationRequestFailed)
                        } else {
                            completion(nil)
                        }
                    })
                    settings.onTokenizeSuccess(token, { error in
                        if error.exists {
                            completion(PrimerError.tokenizationRequestFailed)
                        } else {
                            completion(nil)
                        }
                    })
                    
                default:
                    completion(nil)
                }
            }
        }
    }
}

#endif
