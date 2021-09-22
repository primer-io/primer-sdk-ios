//
//  ConfirmMandateViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 21/01/2021.
//

#if canImport(UIKit)

internal protocol ConfirmMandateViewModelProtocol {
    var mandate: DirectDebitMandate { get }
    var formCompleted: Bool { get set }
    var businessDetails: BusinessDetails? { get }
    var amount: String { get }
    func loadConfig(_ completion: @escaping (Error?) -> Void)
    func confirmMandateAndTokenize(_ completion: @escaping (Error?) -> Void)
    func eraseData()
}

internal class ConfirmMandateViewModel: ConfirmMandateViewModelProtocol {
    
    var resumeHandler: ResumeHandlerProtocol!
    
    var mandate: DirectDebitMandate {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.directDebitMandate
    }

    var formCompleted: Bool {
        get {
            let state: AppStateProtocol = DependencyContainer.resolve()
            return state.directDebitFormCompleted
        }
        set {
            let state: AppStateProtocol = DependencyContainer.resolve()
            state.directDebitFormCompleted = newValue
        }
    }

    var businessDetails: BusinessDetails? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.businessDetails
    }

    var amount: String {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if settings.directDebitHasNoAmount { return "" }

        guard let amount = settings.amount else {
            return ""
        }

        guard let currency = settings.currency else {
            return ""
        }

        return amount.toCurrencyString(currency: currency)
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
            paymentMethodConfigService.fetchConfig({ err in
                if let err = err {
                    completion(err)
                } else {
                    let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                    vaultService.loadVaultedPaymentMethods(completion)
                }
            })
        } else {
            let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
            clientTokenService.loadCheckoutConfig({ err in
                if let err = err {
                    completion(err)
                } else {
                    let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                    paymentMethodConfigService.fetchConfig({ err in
                        if let err = err {
                            completion(err)
                        } else {
                            let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                            vaultService.loadVaultedPaymentMethods(completion)
                        }
                    })
                }
            })
        }
    }

    func confirmMandateAndTokenize(_ completion: @escaping (Error?) -> Void) {
        let directDebitService: DirectDebitServiceProtocol = DependencyContainer.resolve()
        directDebitService.createMandate({ err in
            if err != nil {
                completion(PrimerError.directDebitSessionFailed)
            } else {
                let state: AppStateProtocol = DependencyContainer.resolve()
                let request = PaymentMethodTokenizationRequest(
                    paymentInstrument: PaymentInstrument(gocardlessMandateId: state.mandateId),
                    state: state
                )
                
                let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()

                tokenizationService.tokenize(request: request) { result in
                    switch result {
                    case .failure(let error):
                        completion(error)
                    case .success(let token):
                        state.directDebitMandate = DirectDebitMandate(address: Address())
                        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                        settings.authorizePayment(token, completion)
                        settings.onTokenizeSuccess(token, completion)
                        Primer.shared.delegate?.onTokenizeSuccess?(token, resumeHandler: self.resumeHandler)
                    }
                }
            }
        })
    }

    func eraseData() {
        let state: AppStateProtocol = DependencyContainer.resolve()
        state.directDebitMandate = DirectDebitMandate()
    }
}

extension ConfirmMandateViewModel: ResumeHandlerProtocol {
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
        try? ClientTokenService.storeClientToken(clientToken)
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
