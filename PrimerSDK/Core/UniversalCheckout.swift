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

struct VaultRequest: Encodable {
    
}

struct PayMethods: Decodable {
    var data: [PaymentMethodToken]
}

class UniversalCheckout: NSObject, UniversalCheckoutProtocol {
    
    var selectedPaymentMethod: String = ""
    var paymentMethodVMs: [PaymentMethodVM] = []
    
    private let context: Context
    private var authTokenProvider: ClientTokenProviderProtocol?
    private var paymentMethods: [PaymentMethodToken] = []
    private let customerId: String
    private let clientTokenRequestCallback: (_ completionHandler: @escaping (Result<ClientTokenResponse, Error>) -> Void) -> Void
    private let authPay: (_ result: PaymentMethodToken, _ completion:  @escaping (Result<Bool, Error>) -> Void) -> Void
    
    var amount: Int = 0
    
    init(
        context: Context,
        customerId: String,
        authPay: @escaping (_ result: PaymentMethodToken, _ completion:  @escaping (Result<Bool, Error>) -> Void) -> Void,
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
        customerId: String
    ) {
        
        let vc = VaultViewController(self)
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
    
    func showScanner(_ controller: UIViewController) {
        let vc = CardScannerVC(self)
        let td = TransitionDelegate()
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = td
        controller.present(vc, animated: true, completion: nil)
    }
    
    func loadCheckoutConfig(_ completion: @escaping () -> Void) {
        self.clientTokenRequestCallback({ result in
            do {
                let token = try result.get()
                
                guard let clientToken = token.clientToken else { return }
                
                let provider = ClientTokenProvider(clientToken)
                let decodedToken = provider.getDecodedClientToken()
                //set token details
                print(decodedToken)
                //call completion handler
                completion()
            } catch {
                
            }
        })
    }
    
    func loadPaymentMethods(_ completion: @escaping (Result<Bool, Error>) -> Void) {
        self.clientTokenRequestCallback({ result in
            
            do {
                let token = try result.get()
                guard let clientToken = token.clientToken else { return }
                
                let provider = ClientTokenProvider(clientToken)
                let decodedToken = provider.getDecodedClientToken()
                //set token details
                print(decodedToken)
                
                self.authTokenProvider = provider
                
                print("tokenizing 😜")
                
                let urlString = "https://api.sandbox.primer.io/payment-instruments?customer_id=customer_1"
                
                guard let url = URL(string: urlString) else { return }
                
                let api = APIClient()
                
                api.get(provider.getDecodedClientToken(), url: url, completion: { result2 in
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
                        completion(.success(true))
                    } catch {
                        let tokenizationError = PaymentMethodTokenizationError(description: error.localizedDescription)
                        completion(.failure(tokenizationError))
                    }
                })
                
            } catch {
                
            }
        })
    }
    
    func authorizePayment(_ completion: @escaping (Result<Bool, Error>) -> Void) {
        
        if (self.selectedPaymentMethod.count > 0) {
            
            print("already got a token from vault! 🤖")
            
            let token = self.paymentMethods.first(where: {
                method in
                return method.token == self.selectedPaymentMethod
            })
            
            guard token != nil else { return }
            
            if let unwrapped = token {
                print("unwrapped token! 🎁")
                self.authPay(unwrapped, completion)
            }
            
        } else {
            self.tokenizePaymentMethod({ result in
                switch result {
                case .failure(let err):
                    print("request failed:")
                    completion(.failure(err))
                case .success(let token):
                    print("🥳 got token: \(token)")
                    self.authPay(token, completion)
                }
            })
        }
    }
    
    func addPaymentMethod(_ oompletion: @escaping () -> Void) {
        print("adding payment method 😜")
        
        guard let url = URL(string: "https://api.sandbox.primer.io/payment-instruments") else { return }
        
        let compl2 = oompletion
        
        let paymentInstrument = PaymentInstrument(number: "4111111111111111", cvv: "737", expirationMonth: "03", expirationYear: "2030", cardholderName: "J Doe")
        let data = PaymentMethodTokenizationRequest(paymentInstrument: paymentInstrument, tokenType: "MULTI_USE", paymentFlow: "VAULT", customerId: "customer_1")
        let api = APIClient()
        
        api.post(authTokenProvider?.getDecodedClientToken(), url: url, body: data, completion: { result in
            do {
                let data = try result.get()
                let token = try JSONDecoder().decode(PaymentMethodToken.self, from: data)
                print("TOKEN 🌋", token)
                compl2()
            } catch {
                //                    let tokenizationError = PaymentMethodTokenizationError(description: error.localizedDescription)
                //                    onTokenizeSuccess(.failure(tokenizationError))
            }
        })
    }
    
    func deletePaymentMethod(id: String, _ oompletion: @escaping (Error?) -> Void) {
        print("deleting payment method 🥴", id)
        
        guard let url = URL(string: "https://api.sandbox.primer.io/payment-instruments/\(id)/vault") else { return }
        
        let api = APIClient()
        
        api.delete(authTokenProvider?.getDecodedClientToken(), url: url, completion: { result in
            do {
                let data = try result.get()
                let token = try JSONDecoder().decode(PaymentMethodToken.self, from: data)
                print("TOKEN 🌋", token)
                oompletion(nil)
            } catch {
                //                    let tokenizationError = PaymentMethodTokenizationError(description: error.localizedDescription)
                //                    onTokenizeSuccess(.failure(tokenizationError))
            }
        })
    }
    
    private func tokenizePaymentMethod(_ onTokenizeSuccess: @escaping (Result<PaymentMethodToken, PaymentMethodTokenizationError>) -> Void) {
        print("tokenizing 😜")
        
        guard let url = URL(string: "http://localhost:8020/payment-method-token") else { return }
        
        let paymentInstrument = PaymentInstrument(number: "4111111111111111", cvv: "737", expirationMonth: "03", expirationYear: "2030", cardholderName: "J Doe")
        let data = PaymentMethodTokenizationRequest(paymentInstrument: paymentInstrument,tokenType: "MULTI_USE", paymentFlow: "VAULT", customerId: self.customerId)
        let api = APIClient()
        
        api.post(authTokenProvider?.getDecodedClientToken(), url: url, body: data, completion: { result in
            do {
                let data = try result.get()
                let token = try JSONDecoder().decode(PaymentMethodToken.self, from: data)
                print("TOKEN 🌋", token)
                onTokenizeSuccess(.success(token))
            } catch {
                let tokenizationError = PaymentMethodTokenizationError(description: error.localizedDescription)
                onTokenizeSuccess(.failure(tokenizationError))
            }
        })
    }
    
}
