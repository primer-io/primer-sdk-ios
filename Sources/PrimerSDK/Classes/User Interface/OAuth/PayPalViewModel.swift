#if canImport(UIKit)

import UIKit
import AuthenticationServices
import SafariServices

class PayPalViewModel: NSObject, PrimerOAuthViewModel {
    
    var host: OAuthHost = .paypal
    var didPresentPaymentMethod: (() -> Void)?
    private var session: Any!
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    func tokenize() -> Promise <PaymentMethodToken> {
        return Promise { seal in
            firstly {
                self.fetchOAuthURL()
            }
            .then { url -> Promise<URL> in
                return self.createOAuthSession(url)
            }
            .then { url -> Promise<PaymentInstrument> in
                return self.generatePaypalPaymentInstrument()
            }
            .then { instrument -> Promise<PaymentMethodToken> in
                return self.tokenize(instrument: instrument)
            }
            .done { token in
                seal.fulfill(token)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func fetchOAuthURL() -> Promise<URL> {
        return Promise { seal in
            let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
            viewModel.generateOAuthURL(host, with: { result in
                switch result {
                case .success(let urlStr):
                    guard let url = URL(string: urlStr) else {
                        seal.reject(PrimerError.failedToLoadSession)
                        return
                    }
                    
                    seal.fulfill(url)
                case .failure(let err):
                    seal.reject(err)
                }
            })
            
        }
    }
    
    private func createOAuthSession(_ url: URL) -> Promise<URL> {
        return Promise { seal in
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            guard let urlScheme = settings.urlScheme else {
                seal.reject(PrimerError.missingURLScheme)
                return
            }
            
            if #available(iOS 13, *) {
                session =  ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme: urlScheme,
                    completionHandler: { (url, error) in
                        if let error = error {
                            seal.reject(error)
                            
                        } else if let url = url {
                            seal.fulfill(url)
                        }
                    }
                )
                
                (session as! ASWebAuthenticationSession).presentationContextProvider = self
                (session as! ASWebAuthenticationSession).start()
                
            } else if #available(iOS 11, *) {
                session = SFAuthenticationSession(
                    url: url,
                    callbackURLScheme: urlScheme,
                    completionHandler: { (url, err) in
                        if let err = err {
                            seal.reject(err)
                            
                        } else if let url = url {
                            seal.fulfill(url)
                        }
                    }
                )

                (session as! SFAuthenticationSession).start()
                didPresentPaymentMethod?()
            }
        }
    }
    
    private func generatePaypalPaymentInstrument() -> Promise<PaymentInstrument> {
        return Promise { seal in
            generatePaypalPaymentInstrument { result in
                switch result {
                case .success(let paymentInstrument):
                    seal.fulfill(paymentInstrument)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    private func generatePaypalPaymentInstrument(_ completion: @escaping (Result<PaymentInstrument, Error>) -> Void) {
        switch Primer.shared.flow.internalSessionFlow.uxMode {
        case .CHECKOUT:
            let state: AppStateProtocol = DependencyContainer.resolve()
            guard let orderId = state.orderId else {
                completion(.failure(PrimerError.orderIdMissing))
                return
            }
            
            let paymentInstrument = PaymentInstrument(paypalOrderId: orderId)
            completion(.success(paymentInstrument))
            
        case .VAULT:
            let state: AppStateProtocol = DependencyContainer.resolve()
            guard let confirmedBillingAgreement = state.confirmedBillingAgreement else {
                generateBillingAgreementConfirmation { [weak self] err in
                    if let err = err {
                        completion(.failure(err))
                    } else {
                        self?.generatePaypalPaymentInstrument(completion)
                    }
                }
                return
            }
            let paymentInstrument = PaymentInstrument(
                paypalBillingAgreementId: confirmedBillingAgreement.billingAgreementId,
                shippingAddress: confirmedBillingAgreement.shippingAddress,
                externalPayerInfo: confirmedBillingAgreement.externalPayerInfo
            )
            
            completion(.success(paymentInstrument))
        }
    }
    
    private func generateBillingAgreementConfirmation(_ completion: @escaping (Error?) -> Void) {
        let paypalService: PayPalServiceProtocol = DependencyContainer.resolve()
        paypalService.confirmBillingAgreement({ result in
            switch result {
            case .failure(let error):
                log(logLevel: .error, title: "ERROR!", message: error.localizedDescription, prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
                completion(PrimerError.payPalSessionFailed)
            case .success:
                completion(nil)
            }
        })
    }
    
    private func tokenize(instrument: PaymentInstrument) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            let state: AppStateProtocol = DependencyContainer.resolve()
            let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
            
            let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
            tokenizationService.tokenize(request: request) { [weak self] result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                    
                case .success(let token):
                    seal.fulfill(token)
                }
            }
        }
    }
    
}

@available(iOS 11.0, *)
extension PayPalViewModel: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 12.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow ?? ASPresentationAnchor()
    }
    
}

extension SFSafariViewController {
    override open var modalPresentationStyle: UIModalPresentationStyle {
        get { return .fullScreen}
        set { super.modalPresentationStyle = newValue }
    }
}

#endif
