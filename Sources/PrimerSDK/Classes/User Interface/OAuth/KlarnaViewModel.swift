#if canImport(UIKit)

class KlarnaViewModel: PrimerOAuthViewModel {
    
    var host: OAuthHost = .klarna
    var didPresentPaymentMethod: (() -> Void)?
    private let webViewController = WebViewController()

    func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
            viewModel.generateOAuthURL(.klarna, with: { result in
                
                switch result {
                case .failure(let err):
                    seal.reject(err)
                    
                case .success(let urlString):
                    guard let url = URL(string: urlString) else {
                        seal.reject(PrimerError.invalidValue)
                        return
                    }
                    
                    self.webViewController.url = url
                    self.webViewController.webViewCompletion = { (_, err) in
                        if let err = err {
                            seal.reject(err)
                            
                        } else {
                            self.onWebViewResponse { result in
                                switch result {
                                case .success(let token):
                                    seal.fulfill(token)
                                case .failure(let err):
                                    seal.reject(err)
                                }
                            }
                        }
                    }
                    
                    self.webViewController.modalPresentationStyle = .fullScreen
                    self.didPresentPaymentMethod?()
                    Primer.shared.primerRootVC?.present(self.webViewController, animated: true, completion: nil)
                }
            })
        }
    }
    
    private func onWebViewResponse(_ completion: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
        let klarnaService: KlarnaServiceProtocol = DependencyContainer.resolve()

        if Primer.shared.flow.internalSessionFlow.vaulted {
            klarnaService.createKlarnaCustomerToken { (result) in
                switch result {
                case .failure(let err):
                    completion(.failure(err))
                    
                case .success(let res):
                    let instrument = PaymentInstrument(klarnaCustomerToken: res.customerTokenId, sessionData: res.sessionData)

                    let state: AppStateProtocol = DependencyContainer.resolve()
                    let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)

                    let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
                    tokenizationService.tokenize(request: request) { result in
                        switch result {
                        case .failure(let err):
                            completion(.failure(err))
                            
                        case .success(let token):
                            completion(.success(token))
                        }
                    }
                }
            }

        } else {
            klarnaService.finalizePaymentSession { result in
                switch result {
                case .failure(let err):
                    completion(.failure(err))
                    
                case .success(let res):
                    let state: AppStateProtocol = DependencyContainer.resolve()
                    
                    let instrument = PaymentInstrument(klarnaAuthorizationToken: state.authorizationToken, sessionData: res.sessionData)

                    let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)

                    let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
                    tokenizationService.tokenize(request: request) { result in
                        switch result {
                        case .failure(let err):
                            completion(.failure(err))
                            
                        case .success(let token):
                            completion(.success(token))
                        }
                    }
                }
            }
        }
    }
    
}

#endif
