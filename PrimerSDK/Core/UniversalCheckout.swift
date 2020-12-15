import UIKit

struct PaymentMethodConfig: Decodable {
    let coreUrl: String?
    let pciUrl: String?
    let paymentMethods: [ConfigPaymentMethod]?
}

struct ConfigPaymentMethod: Decodable {
    let id: String?
    let type: String?
}

enum PrimerEndpoint: String {
    case PCI = "PRIMER_PCI_API_URL"
    case CORE = "PRIMER_CORE_API_URL"
}

class UniversalCheckout: NSObject, UniversalCheckoutProtocol {
    
    // Endpoints
    let coreEndpoint = ProcessInfo.processInfo.environment[PrimerEndpoint.CORE.rawValue] ?? ""
    let pciEndpoint = ProcessInfo.processInfo.environment[PrimerEndpoint.PCI.rawValue] ?? ""
    
    var selectedPaymentMethod: String = ""
    var paymentMethodVMs: [PaymentMethodVM] = []
    
    private var authTokenProvider: ClientTokenProviderProtocol?
    private let customerId: String?
    private let clientTokenRequestCallback: (_ completionHandler: @escaping (Result<ClientTokenResponse, Error>) -> Void) -> Void
    private let onTokenizeSuccess: (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void
    private let api = APIClient()
    private var decodedClientToken: ClientToken?
    private var paymentMethodConfig: PaymentMethodConfig?
    
    // Services
    private var payPalService: PayPalService?
    private var vaultService: VaultService?
    
    var orderId: String?
    var uxMode: UXMode = UXMode.CHECKOUT
    var amount: Int
    var currency: Currency
    
    var selectedCard: String? {
        get { return vaultService?.selectedPaymentMethod }
    }
    
    var paymentMethods: [PaymentMethodVM]? {
        get { return vaultService?.paymentMethodVMs }
    }
    
    init(
        customerId: String? = nil,
        amount: Int,
        currency: Currency,
        uxMode: UXMode,
        onTokenizeSuccess: @escaping (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void,
        authTokenProvider: ClientTokenProvider?,
        clientTokenCallback: @escaping (_ completionHandler: @escaping (Result<ClientTokenResponse, Error>) -> Void) -> Void
    ) {
        self.authTokenProvider = authTokenProvider
        self.onTokenizeSuccess = onTokenizeSuccess
        self.clientTokenRequestCallback = clientTokenCallback
        self.customerId = customerId
        self.amount = amount
        self.currency = currency
        self.uxMode = uxMode
    }
    
    /** display intitial Primer checkout view. Can be direct checkout or vault checkout */
    func showCheckout(_ delegate: PrimerCheckoutDelegate) {
        switch uxMode {
        case .VAULT:
            let viewController = VaultViewController(self)
            viewController.modalPresentationStyle = .custom
            let transitioningDelegate = TransitionDelegate()
            viewController.transitioningDelegate = transitioningDelegate
            delegate.present(viewController, animated: true, completion: nil)
        case .CHECKOUT:
            let viewController = PaymentMethodViewController(loadCheckoutConfig, checkout: self)
            viewController.modalPresentationStyle = .custom
            let transitioningDelegate = TransitionDelegate()
            viewController.transitioningDelegate = transitioningDelegate
            delegate.present(viewController, animated: true, completion: nil)
        }
    }
    
    func showCardForm(_ controller: UIViewController, delegate: ReloadDelegate) {
        let vc = AddCardViewController(self)
        let td = TransitionDelegate()
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = td
        vc.reloadDelegate = delegate
        controller.present(vc, animated: true, completion: nil)
    }
    
    func showScanner(_ controller: UIViewController & CreditCardDelegate) {
        let vc = CardScannerVC(self)
        let td = TransitionDelegate()
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = td
        vc.creditCardDelegate = controller
        controller.present(vc, animated: true, completion: nil)
    }
    
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        self.clientTokenRequestCallback({ result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let token):
                guard let clientToken = token.clientToken else { return }
                let provider = ClientTokenProvider(clientToken)
                let decodedToken = provider.getDecodedClientToken()
                self.decodedClientToken = decodedToken
                self.fetchPaymentMethodConfig(completion)
            }
        })
    }
    
    func reloadVault(_ completion: @escaping (Error?) -> Void) {
        guard let service = self.vaultService else { return }
        service.loadVaultedPaymentMethods(completion)
    }
    
    func payWithPayPal(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let service = self.payPalService else { return }
        service.getAccessToken(completion)
    }
    
    func fetchPaymentMethodConfig(_ completion: @escaping (Error?) -> Void) {
        guard let token = self.decodedClientToken else { return }
        guard let apiURL = URL(string: "\(coreEndpoint)/client-sdk/configuration") else { return }
        self.api.get(token, url: apiURL, completion: { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let data):
                do {
                    let config = try JSONDecoder().decode(PaymentMethodConfig.self, from: data)
                    self.paymentMethodConfig = config
                    config.paymentMethods?.forEach({ method in
                        if (method.type == "PAYPAL") {
                            guard let id = method.id else { return }
                            self.payPalService = PayPalService.init(clientId: id, clientToken: token, amount: self.amount, currency: self.currency)
                        }
                    })
                    
                    if (self.uxMode == UXMode.VAULT) {
                        self.vaultService = VaultService(clientToken: token, api: self.api)
                        self.vaultService?.loadVaultedPaymentMethods(completion)
                    } else {
                        completion(nil)
                    }
                } catch {
                    completion(error)
                }
                
            }
        })
    }
    
    func authorizePayment(
        paymentInstrument: PaymentInstrument?,
        onAuthorizationSuccess: @escaping (Error?) -> Void
    ) {
        if (self.selectedPaymentMethod.count > 0) {
            guard let methods = self.vaultService?.paymentMethods else { return }
            let token = methods.first(where: { method in
                return method.token == self.selectedPaymentMethod
            })
            guard token != nil else { return }
            if let unwrapped = token { self.onTokenizeSuccess(unwrapped, onAuthorizationSuccess) }
        } else {
            if let paymentInstrument = paymentInstrument {
                let request = PaymentMethodTokenizationRequest(
                    paymentInstrument: paymentInstrument,
                    tokenType: TokenType.multiUse,
                    paymentFlow: nil,
                    customerId: "customer_1"
                )
                func onTokenizeSuccess(result: Result<PaymentMethodToken, Error>) {
                    switch result {
                    case .failure(let err):
                        onAuthorizationSuccess(err)
                    case .success(let token):
                        self.onTokenizeSuccess(token, onAuthorizationSuccess)
                    }
                }
                self.tokenizeCard(request: request, onTokenizeSuccess: onTokenizeSuccess)            }
        }
    }
    
    func tokenizeCard(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, Error>) -> Void
    ) {
        guard let url = URL(string: "\(pciEndpoint)/payment-instruments") else { return }
        guard let clientToken = decodedClientToken else { return }
        self.api.post(clientToken, body: request, url: url, completion: { result in
            do {
                let data = try result.get()
                let token = try JSONDecoder().decode(PaymentMethodToken.self, from: data)
                onTokenizeSuccess(.success(token))
            } catch {
                let tokenizationError = PaymentMethodTokenizationError(description: error.localizedDescription)
                onTokenizeSuccess(.failure(tokenizationError))
            }
        })
    }
    
    func addPaymentMethod(
        request: PaymentMethodTokenizationRequest,
        onSuccess: @escaping (Error?) -> Void
    ) {
        tokenizeCard(request: request, onTokenizeSuccess: { result in
            switch result {
            case .failure(let err):
                onSuccess(err)
            case .success(let token):
                switch self.uxMode {
                case .VAULT:
                    onSuccess(nil)
                case .CHECKOUT:
                    print("😝 token!", token.token!)
                    self.onTokenizeSuccess(token, onSuccess)
                }
            }
        })
    }
    
    func deletePaymentMethod(id: String, _ onDeletetionSuccess: @escaping (Error?) -> Void) {
        guard let url = URL(string: "\(pciEndpoint)/payment-instruments/\(id)/vault") else { return }
        guard let token = decodedClientToken else { return }
        self.api.delete(token, url: url, completion: { result in
            switch result {
            case .failure(let error):
                onDeletetionSuccess(error)
            case .success:
                onDeletetionSuccess(nil)
            }
        })
    }
}
