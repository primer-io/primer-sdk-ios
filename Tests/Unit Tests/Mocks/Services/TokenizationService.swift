////
////  TokenizationService.swift
////  PrimerSDKTests
////
////  Created by Carl Eriksson on 16/01/2021.
////
//
// #if canImport(UIKit)
//
// @testable import PrimerSDK
//
// class MockTokenizationService: TokenizationServiceProtocol {
//
//    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
//
//    var paymentInstrumentType: String
//    var tokenType: String
//    var tokenizeCalled = false
//    lazy var paymentMethodTokenJSON: [String: Any] = [
//        "token": "payment_method_token",
//        "analyticsId": "analytics_id",
//        "tokenType":  tokenType,
//        "paymentInstrumentType": paymentInstrumentType
//    ]
//
//    required init(apiClient: PrimerAPIClientProtocol) {
//
//    }
//
//    init(paymentInstrumentType: String, tokenType: String) {
//        self.paymentInstrumentType = paymentInstrumentType
//        self.tokenType = tokenType
//    }
//
//    func tokenize(requestBody: Request.Body.Tokenization, onTokenizeSuccess: @escaping (Result<PrimerPaymentMethodTokenData, Error>) -> Void) {
//        tokenizeCalled = true
//
//        let paymentMethodTokenData = try! JSONSerialization.data(withJSONObject: paymentMethodTokenJSON, options: .fragmentsAllowed)
//        let token = try! JSONDecoder().decode(PrimerPaymentMethodTokenData.self, from: paymentMethodTokenData) //PaymentMethodToken(token: "tokenID", paymentInstrumentType: .paymentCard, vaultData: VaultData())
//        return onTokenizeSuccess(.success(token))
//    }
//
//    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData> {
//        return Promise { seal in
//            self.tokenize(requestBody: requestBody) { result in
//                switch result {
//                case .failure(let err):
//                    seal.reject(err)
//                case .success(let res):
//                    seal.fulfill(res)
//                }
//            }
//        }
//    }
// }
//
// #endif
