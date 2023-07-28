#if canImport(UIKit)

import Foundation

internal protocol TokenizationServiceProtocol {
    
    static var apiClient: PrimerAPIClientProtocol? { get set }
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get set }
    
    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData>
    func exchangePaymentMethodToken(_ paymentMethodTokenId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) -> Promise<PrimerPaymentMethodTokenData>
}

internal class TokenizationService: TokenizationServiceProtocol {
    
    static var apiClient: PrimerAPIClientProtocol?
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            log(logLevel: .verbose, title: nil, message: "Client Token: \(decodedJWTToken)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

            guard let pciURL = decodedJWTToken.pciUrl else {
                let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedJWTToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            log(logLevel: .verbose, title: nil, message: "PCI URL: \(pciURL)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

            guard let url = URL(string: "\(pciURL)/payment-instruments") else {
                let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedJWTToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            log(logLevel: .verbose, title: nil, message: "URL: \(url)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
                       
            let apiClient: PrimerAPIClientProtocol = TokenizationService.apiClient ?? PrimerAPIClient()
            
            apiClient.tokenizePaymentMethod(clientToken: decodedJWTToken, tokenizationRequestBody: requestBody) { (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                    
                case .success(let paymentMethodTokenData):
                    self.paymentMethodTokenData = paymentMethodTokenData
                    seal.fulfill(paymentMethodTokenData)
                }
            }
        }
    }
    
    func exchangePaymentMethodToken(
        _ vaultedPaymentMethodId: String,
        vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let apiClient: PrimerAPIClientProtocol = CheckoutWithVaultedPaymentMethodViewModel.apiClient ?? PrimerAPIClient()
            
            apiClient.exchangePaymentMethodToken(
                clientToken: decodedJWTToken,
                vaultedPaymentMethodId: vaultedPaymentMethodId,
                vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let singleUsePaymentMethod):
                        seal.fulfill(singleUsePaymentMethod)
                    case .failure(let error):
                        seal.reject(error)
                    }
                }
            }
        }
    }
}

#endif
