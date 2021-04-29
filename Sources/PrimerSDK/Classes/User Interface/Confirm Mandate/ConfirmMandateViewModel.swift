//
//  ConfirmMandateViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 21/01/2021.
//

#if canImport(UIKit)

protocol ConfirmMandateViewModelProtocol {
    var mandate: DirectDebitMandate { get }
    var formCompleted: Bool { get set }
    var businessDetails: BusinessDetails? { get }
    var amount: String { get }
    func loadConfig(_ completion: @escaping (Error?) -> Void)
    func confirmMandateAndTokenize(_ completion: @escaping (Error?) -> Void)
    func eraseData()
}

class ConfirmMandateViewModel: ConfirmMandateViewModelProtocol {
    
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

    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if state.decodedClientToken.exists {
            let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            paymentMethodConfigService.fetchConfig({ [weak self] error in
                if error.exists { return completion(error) }
                let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                vaultService.loadVaultedPaymentMethods(completion)
            })
        } else {
            let clientTokenService: ClientTokenServiceProtocol = DependencyContainer.resolve()
            clientTokenService.loadCheckoutConfig({ [weak self] error in
                if error.exists { return completion(error) }
                let paymentMethodConfigService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                paymentMethodConfigService.fetchConfig({ [weak self] error in
                    if error.exists { return completion(error) }
                    let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
                    vaultService.loadVaultedPaymentMethods(completion)
                })
            })
        }
    }

    func confirmMandateAndTokenize(_ completion: @escaping (Error?) -> Void) {
        let directDebitService: DirectDebitServiceProtocol = DependencyContainer.resolve()
        directDebitService.createMandate({ [weak self] error in
            if error.exists { return completion(PrimerError.directDebitSessionFailed) }
            
            
            

            let state: AppStateProtocol = DependencyContainer.resolve()
            let request = PaymentMethodTokenizationRequest(
                paymentInstrument: PaymentInstrument(gocardlessMandateId: state.mandateId),
                state: state
            )
            
            let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()

            tokenizationService.tokenize(request: request) { [weak self] result in
                switch result {
                case .failure(let error):
                    completion(error)
                case .success(let token):
                    state.directDebitMandate = DirectDebitMandate(address: Address())
                    // FIXME: Please review this carefully. I believe that the authorizePayment delegate method should not be called since Direct Debit can only be vaulted. 
                    completion(nil)
//                    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
//                    settings.authorizePayment(token, completion)
                }
            }
        })
    }

    func eraseData() {
        let state: AppStateProtocol = DependencyContainer.resolve()
        state.directDebitMandate = DirectDebitMandate()
    }
}

#endif
