import UIKit

enum PrimerError: String, Error {
    case ClientTokenNull = "Client token is missing."
    case CustomerIDNull = "Customer ID is missing."
}

class CheckoutContext {
    private var authTokenProvider: ClientTokenProviderProtocol?
    private let customerId: String?
    private let clientTokenRequestCallback: (_ completionHandler: @escaping (Result<ClientTokenResponse, Error>) -> Void) -> Void
    private let onTokenizeSuccess: (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void
    private let api = APIClient()
    private var decodedClientToken: ClientToken?
    private var payPalService: PayPalService?
    private var vaultService: VaultService?
    private var tokenizationService: TokenizationService?
    private var paymentMethodConfigService: PaymentMethodConfigService?
    private var router: Router?
    
    var paymentMethodViewModels: [PaymentMethodViewModel] = []
    var orderId: String? { get { return payPalService?.orderId } }
    var selectedCard: String? { get { return vaultService?.selectedPaymentMethod } }
    var uxMode: UXMode
    var amount: Int
    var currency: Currency
    var merchantIdentifier: String
    var countryCode: CountryCode
    var applePayEnabled: Bool
    
    init(
        customerId: String? = nil,
        merchantIdentifier: String,
        countryCode: CountryCode,
        applePayEnabled: Bool,
        amount: Int,
        currency: Currency,
        uxMode: UXMode,
        onTokenizeSuccess: @escaping (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void,
        authTokenProvider: ClientTokenProvider?,
        clientTokenCallback: @escaping (_ completionHandler: @escaping (Result<ClientTokenResponse, Error>) -> Void) -> Void
    ) {
        self.authTokenProvider = authTokenProvider
        self.merchantIdentifier = merchantIdentifier
        self.applePayEnabled = applePayEnabled
        self.countryCode = countryCode
        self.onTokenizeSuccess = onTokenizeSuccess
        self.clientTokenRequestCallback = clientTokenCallback
        self.customerId = customerId
        self.amount = amount
        self.currency = currency
        self.uxMode = uxMode
        self.router = Router(
            cardFormViewControllerDelegate: self,
            applePayViewControllerDelegate: self,
            oAuthViewControllerDelegate: self,
            cardScannerViewControllerDelegate: self,
            vaultCheckoutViewControllerDelegate: self,
            directCheckoutViewControllerDelegate: self
        )
    }
    
    /** display intitial Primer checkout view. Can be direct checkout or vault checkout. */
    func showCheckout(_ controller: UIViewController) {
        switch uxMode {
        case .VAULT: router?.showVaultCheckout(controller)
        case .CHECKOUT: router?.showDirectCheckout(controller)
        }
    }
    
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        self.clientTokenRequestCallback({ result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let token):
                guard let clientToken = token.clientToken else { return completion(PrimerError.ClientTokenNull) }
                let provider = ClientTokenProvider(clientToken)
                let decodedToken = provider.getDecodedClientToken()
                self.decodedClientToken = decodedToken
                guard let router = self.router else { return }
                let configService = PaymentMethodConfigService(
                    clientToken: decodedToken,
                    api: self.api,
                    router: router
                )
                self.paymentMethodConfigService = configService
                configService.fetchConfig({ error in
                    self.prepareCheckoutViewModels(completion)
                })
            }
        })
    }
    
    func prepareCheckoutViewModels(_ completion: @escaping (Error?) -> Void) {
        if (self.uxMode == UXMode.VAULT) {
            guard let clientToken = self.decodedClientToken else { return completion(PrimerError.ClientTokenNull) }
            guard let ID = customerId else { return }
            self.vaultService = VaultService(clientToken: clientToken, api: self.api, customerID: ID)
            self.vaultService?.loadVaultedPaymentMethods(completion)
        } else {
            guard let service = paymentMethodConfigService else { return }
            guard let methods = service.paymentMethodConfig?.paymentMethods else { return }
            paymentMethodServiceFactory(configMethods: methods)
            self.paymentMethodViewModels = paymentMethodViewModelFactory(configMethods: methods)
            completion(nil)
        }
    }
    
    func paymentMethodServiceFactory(configMethods: [ConfigPaymentMethod]) {
        configMethods.forEach({ method in
            guard let clientToken = self.decodedClientToken else { return }
            guard let type = method.type else { return }
            switch type {
            case .PAYPAL:
                guard let id = method.id else { return }
                self.payPalService = PayPalService.init(
                    clientId: id,
                    clientToken: clientToken,
                    amount: self.amount,
                    currency: self.currency
                )
            default:
                print("no service!")
            }
        })
    }
    
    func paymentMethodViewModelFactory(configMethods: [ConfigPaymentMethod]) -> [PaymentMethodViewModel]  {
        var models: [PaymentMethodViewModel] = []
        guard let router = router else { return models }
        configMethods.forEach({ method in
            guard let type = method.type else { return }
            switch type {
            case .APPLE_PAY:
                
                if (applePayEnabled) {
                    let model = PaymentMethodViewModel(
                        type: type,
                        presentTokenizingViewController: router.showApplePay
                    )
                    models.append(model)
                }
                
            case .PAYPAL:
                let model = PaymentMethodViewModel(
                    type: type,
                    presentTokenizingViewController: router.showOAuth
                )
                models.append(model)
            case .PAYMENT_CARD:
                let model = PaymentMethodViewModel(
                    type: type,
                    presentTokenizingViewController: router.showCardForm
                )
                models.append(model)
            default:
                print("no view model!")
            }
        })
        return models
    }
    
    func reloadVault(_ completion: @escaping (Error?) -> Void) {
        self.vaultService?.loadVaultedPaymentMethods(completion)
    }
}

extension CheckoutContext: DirectCheckoutViewControllerDelegate {
    var amountViewModel: AmountViewModel {
        return AmountViewModel(amount: amount, currency: currency)
    }
}
extension CheckoutContext: CardFormViewControllerDelegate {
    func showScanner(_ controller: UIViewController) {
        router?.showScanner(controller)
    }
    
    func reload() {
        
    }
    
    var viewModels: [PaymentMethodViewModel]? {
        return paymentMethodViewModels
    }
    
    func addPaymentMethod(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        
        var request: PaymentMethodTokenizationRequest
        
        switch uxMode {
        case .CHECKOUT:
            request = PaymentMethodTokenizationRequest(
                paymentInstrument: instrument,
                tokenType: TokenType.singleUse,
                paymentFlow: nil,
                customerId: nil
            )
        case .VAULT:
            guard let id = customerId else { return }
            request = PaymentMethodTokenizationRequest(
                paymentInstrument: instrument,
                tokenType: TokenType.multiUse,
                paymentFlow: PaymentFlow.vault,
                customerId: id
            )
        }
        
        guard let token = decodedClientToken else { return completion(PrimerError.ClientTokenNull) }
        
        self.tokenizationService = TokenizationService(clientToken: token, api: api)
        
        guard let tokenizationService = self.tokenizationService else { return }
        
        tokenizationService.tokenize(request: request, onTokenizeSuccess: { result in
            switch result {
            case .failure(let err):
                completion(err)
            case .success(let token):
                switch self.uxMode {
                case .VAULT:
                    completion(nil)
                case .CHECKOUT:
                    self.onTokenizeSuccess(token, completion)
                }
            }
        })
    }
    
}

extension CheckoutContext: OAuthViewControllerDelegate {
    func generateURL(_ completion: @escaping (Result<String, Error>) -> Void) {
        self.payPalService?.getAccessToken(completion)
    }
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        addPaymentMethod(instrument: instrument, completion: completion)
    }
}

extension CheckoutContext: VaultCheckoutViewControllerDelegate {
    func showApplePayView(_ controller: UIViewController) {
        router?.showApplePay(controller)
    }
    
    var paymentMethods: [VaultedPaymentMethodViewModel] {
        return vaultService?.paymentMethodVMs ?? []
    }
    
    var selectedPaymentMethodId: String {
        return selectedCard ?? ""
    }
    
    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        loadCheckoutConfig(completion)
    }
    
    func showPaymentMethodView(_ controller: UIViewController) {
        let vc = VaultPaymentMethodViewController(self)
        controller.present(vc, animated: true, completion: nil)
    }
    
    func authorizePayment(_ completion: @escaping (Error?) -> Void) {
        guard let service = vaultService else { return }
        let id = service.selectedPaymentMethod
        let tokens = service.paymentMethods
        let selectedToken = tokens.first(where: { token in
            guard let tokenId = token.token else { return false }
            return tokenId == id
        })
        guard let token = selectedToken else { return }
        self.onTokenizeSuccess(token, completion)
    }
}

extension CheckoutContext: VaultPaymentMethodViewControllerDelegate {
    var selectedId: String {
        get { return vaultService?.selectedPaymentMethod ?? "" }
        set {
            vaultService?.selectedPaymentMethod = newValue
        }
    }
    
    func showAddCardFormView(_ controller: UIViewController) {
        router?.showCardForm(controller)
    }
    
    func deletePaymentMethod(_ id: String, completion: @escaping (Error?) -> Void) {
        vaultService?.deleteVaultedPaymentMethod(id: id, completion)
    }
}

extension CheckoutContext: CardScannerViewControllerDelegate {
    func setScannedCardDetails(_ details: CreditCardDetails) {
        //        self.cardFormView.nameTF.text = details.name
        //        let numberMask = Veil(pattern: "#### #### #### ####")
        //        self.cardFormView.cardTF.text = numberMask.mask(input: details.number!, exhaustive: false)
        //        let expYr =  details.expiryYear!.count == 2 ? "20\(details.expiryYear!)" :  String(details.expiryYear!)
        //        self.cardFormView.expTF.text = String(format: "%02d", details.expiryMonth!) + "/" + expYr
    }
}

extension CheckoutContext: ApplePayViewControllerDelegate {}
