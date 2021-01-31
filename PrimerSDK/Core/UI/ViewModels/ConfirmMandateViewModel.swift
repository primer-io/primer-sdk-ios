//
//  ConfirmMandateViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 21/01/2021.
//

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
        return state.directDebitMandate
    }
    
    var formCompleted: Bool {
        get { return state.directDebitFormCompleted }
        set { state.directDebitFormCompleted = newValue }
    }
    
    var businessDetails: BusinessDetails? {
        return state.settings.businessDetails
    }
    
    var amount: String {
        return state.settings.amount.toCurrencyString(currency: state.settings.currency)
    }
    
    private let state: AppStateProtocol
    private let directDebitService: DirectDebitServiceProtocol
    private let tokenizationService: TokenizationServiceProtocol
    private let paymentMethodConfigService: PaymentMethodConfigServiceProtocol
    private let clientTokenService: ClientTokenServiceProtocol
    private let vaultService: VaultServiceProtocol
    
    init(context: CheckoutContext) {
        self.state = context.state
        self.directDebitService = context.serviceLocator.directDebitService
        self.tokenizationService = context.serviceLocator.tokenizationService
        self.paymentMethodConfigService = context.serviceLocator.paymentMethodConfigService
        self.clientTokenService = context.serviceLocator.clientTokenService
        self.vaultService = context.serviceLocator.vaultService
    }
    
    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        if (state.decodedClientToken.exists) {
            paymentMethodConfigService.fetchConfig({ [weak self] error in
                if (error.exists) { return completion(error) }
                self?.vaultService.loadVaultedPaymentMethods(completion)
            })
        } else {
            clientTokenService.loadCheckoutConfig({ [weak self] error in
                if (error.exists) { return completion(error) }
                self?.paymentMethodConfigService.fetchConfig({ [weak self] error in
                    if (error.exists) { return completion(error) }
                    self?.vaultService.loadVaultedPaymentMethods(completion)
                })
            })
        }
    }
    
    func confirmMandateAndTokenize(_ completion: @escaping (Error?) -> Void) {
        directDebitService.createMandate({ [weak self] error in
            if (error.exists) { return completion(PrimerError.DirectDebitSessionFailed) }
            
            guard let state = self?.state else { return completion(PrimerError.DirectDebitSessionFailed) }
            
            let request = PaymentMethodTokenizationRequest(
                paymentInstrument: PaymentInstrument(gocardlessMandateId: state.mandateId),
                state: state
            )
            
            self?.tokenizationService.tokenize(request: request) { [weak self] result in
                switch result {
                case .failure(let error): completion(error)
                case .success:
                    
                    self?.state.directDebitMandate = DirectDebitMandate(
                        //        iban: "FR1420041010050500013M02606",
                        address: Address()
                    )
                    
                    completion(nil)
                }
            }
        })
    }
    
    func eraseData() {
        state.directDebitMandate = DirectDebitMandate()
    }
}
