// swiftlint:disable function_body_length

import Foundation

internal protocol TokenizationServiceProtocol {
    static var apiClient: PrimerAPIClientProtocol? { get set }
    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get set }
    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData>
    func exchangePaymentMethodToken(_ paymentMethodTokenId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) -> Promise<PrimerPaymentMethodTokenData>
}

internal class TokenizationService: TokenizationServiceProtocol, LogReporter {
    static var apiClient: PrimerAPIClientProtocol?
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            self.logger.debug(message: "Client Token: \(decodedJWTToken)")
            guard let pciURL = decodedJWTToken.pciUrl else {
                let err = PrimerError.invalidValue(
                    key: "decodedClientToken.pciUrl",
                    value: decodedJWTToken.pciUrl,
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            self.logger.debug(message: "PCI URL: \(pciURL)")
            guard let url = URL(string: "\(pciURL)/payment-instruments") else {
                let err = PrimerError.invalidValue(
                    key: "decodedClientToken.pciUrl",
                    value: decodedJWTToken.pciUrl,
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            self.logger.debug(message: "URL: \(url)")
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
    func exchangePaymentMethodToken( _ vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString)
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
// swiftlint:enable function_body_length
