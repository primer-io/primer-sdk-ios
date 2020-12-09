import UIKit

struct Context {}

enum UXMode {
    case CHECKOUT
    case ADD_PAYMENT_METHOD
}

typealias ShowCheckout = (
    UIViewController,
    UXMode,
    Int?,
    String?
) -> Void

struct PayMethods: Decodable {
    var data: [PaymentMethodToken]
}

class UniversalCheckout: NSObject, UniversalCheckoutProtocol {
    
    var selectedPaymentMethod: String = ""
    var paymentMethodVMs: [PaymentMethodVM] = []
    
    private let context: Context
    private var authTokenProvider: ClientTokenProviderProtocol?
    private var paymentMethods: [PaymentMethodToken] = []
    private let customerId: String?
    private let clientTokenRequestCallback: (_ completionHandler: @escaping (Result<ClientTokenResponse, Error>) -> Void) -> Void
    private let authPay: (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void
    private let api = APIClient()
    private var decodedClientToken: ClientToken?
    
    var uxMode: UXMode = UXMode.CHECKOUT
    
    var amount: Int = 0
    
    init(
        context: Context,
        customerId: String? = nil,
        authPay: @escaping (_ result: PaymentMethodToken, _ completion:  @escaping (Error?) -> Void) -> Void,
        authTokenProvider: ClientTokenProvider?,
        clientTokenCallback: @escaping (_ completionHandler: @escaping (Result<ClientTokenResponse, Error>) -> Void) -> Void
    ) {
        self.context = context
        self.authTokenProvider = authTokenProvider
        self.authPay = authPay
        self.clientTokenRequestCallback = clientTokenCallback
        self.customerId = customerId
    }
    
    func showCheckout(
        _ delegate: PrimerCheckoutDelegate,
        uxMode: UXMode = UXMode.CHECKOUT,
        amount: Int,
        currency: String,
        customerId: String?
    ) {
        self.uxMode = uxMode
        
        let vc = uxMode == UXMode.ADD_PAYMENT_METHOD ? VaultViewController(self) : AddCardViewController(self)
        let td = TransitionDelegate()
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = td
        
        self.amount = amount
        delegate.present(vc, animated: true, completion: nil)
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
    
    func loadCheckoutConfig(_ completion: @escaping (Result<ClientToken, Error>) -> Void) {
        self.clientTokenRequestCallback({ result in
            do {
                let token = try result.get()
                
                guard let clientToken = token.clientToken else { return }
                
                let provider = ClientTokenProvider(clientToken)
                let decodedToken = provider.getDecodedClientToken()
                self.decodedClientToken = decodedToken
                completion(.success(decodedToken))
            } catch {
                completion(.failure(error))
            }
        })
    }
    
    func loadPaymentMethods(_ onTokenizeSuccess: @escaping (Error?) -> Void) {
        self.loadCheckoutConfig({ result in
            switch result {
            case .failure(let err):
                
                onTokenizeSuccess(err)
                
            case .success(let token):
                
                let urlString = "https://api.sandbox.primer.io/payment-instruments?customer_id=customer_1"
                
                guard let url = URL(string: urlString) else { return }
                
                let api = APIClient()
                
                api.get(token, url: url, completion: { result2 in
                    do {
                        let data = try result2.get()
                        let methods = try JSONDecoder().decode(PayMethods.self, from: data)
                        print("TOKEN 🌋", token)
                        self.paymentMethods = methods.data
                        self.paymentMethodVMs = []
                        self.paymentMethodVMs = self.paymentMethods.map({
                            method in
                            return PaymentMethodVM(id: method.token!, last4: method.paymentInstrumentData!.last4Digits!)
                            //                    self.paymentMethodVMs.append(PaymentMethodVM(id: method.token!, last4: method.paymentInstrumentData!.last4Digits!))
                        })
                        self.selectedPaymentMethod = self.paymentMethodVMs[0].id
                        onTokenizeSuccess(nil)
                    } catch {
                        let tokenizationError = PaymentMethodTokenizationError(description: error.localizedDescription)
                        onTokenizeSuccess(tokenizationError)
                    }
                })
            }
            
        })
    }
    
    func authorizePayment(
        paymentInstrument: PaymentInstrument?,
        onAuthorizationSuccess: @escaping (Error?) -> Void
    ) {
        if (self.selectedPaymentMethod.count > 0) {
            
            let token = self.paymentMethods.first(where: {
                method in
                return method.token == self.selectedPaymentMethod
            })
            
            guard token != nil else { return }
            
            if let unwrapped = token { self.authPay(unwrapped, onAuthorizationSuccess) }
            
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
                        self.authPay(token, onAuthorizationSuccess)
                    }
                }
                
                self.tokenizeCard(request: request, onTokenizeSuccess: onTokenizeSuccess)
                
            }
        }
    }
    
    func tokenizeCard(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, Error>) -> Void
    ) {
        guard let url = URL(string: "https://api.sandbox.primer.io/payment-instruments") else { return }
        guard let token = decodedClientToken else { return }
        self.api.post(token, url: url, body: request, completion: { result in
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
                case .ADD_PAYMENT_METHOD:
                    onSuccess(nil)
                case .CHECKOUT:
                    print("😝 token!", token.token)
                    self.authPay(token, onSuccess)
                }
                
            }
        })
    }
    
    func deletePaymentMethod(id: String, _ onDeletetionSuccess: @escaping (Error?) -> Void) {
        
        guard let url = URL(string: "https://api.sandbox.primer.io/payment-instruments/\(id)/vault") else { return }
        guard let token = decodedClientToken else { return }
        
        let api = APIClient()
        
        api.delete(token, url: url, completion: { result in
            
            switch result {
            case .failure(let error):
                onDeletetionSuccess(error)
            case .success:
                onDeletetionSuccess(nil)
            }
        })
    }
    
}
