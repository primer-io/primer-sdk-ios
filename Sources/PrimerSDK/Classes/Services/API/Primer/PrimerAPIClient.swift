//
//  PrimerAPIClient.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

#if canImport(UIKit)

import Foundation

protocol PrimerAPIClientProtocol {
    
    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<GetVaultedPaymentMethodsResponse, Error>) -> Void)
    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken) -> Promise<GetVaultedPaymentMethodsResponse>
    func exchangePaymentMethodToken(clientToken: DecodedClientToken, paymentMethodId: String, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void)
    func deleteVaultedPaymentMethod(clientToken: DecodedClientToken, id: String, completion: @escaping (_ result: Result<Void, Error>) -> Void)
    func fetchConfiguration(clientToken: DecodedClientToken, requestBody: PrimerAPIConfiguration.API.RequestBody?, completion: @escaping (_ result: Result<PrimerAPIConfiguration, Error>) -> Void)
//    func createDirectDebitMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (_ result: Result<DirectDebitCreateMandateResponse, Error>) -> Void)
    func createPayPalOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest, completion: @escaping (_ result: Result<PayPalCreateOrderResponse, Error>) -> Void)
    func createPayPalBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalCreateBillingAgreementResponse, Error>) -> Void)
    func confirmPayPalBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void)
    func createKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (_ result: Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void)
    func createKlarnaCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: CreateKlarnaCustomerTokenAPIRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void)
    func finalizeKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void)
    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: TokenizationRequest, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void)
    func begin3DSAuth(clientToken: DecodedClientToken, paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void)
    func continue3DSAuth(clientToken: DecodedClientToken, threeDSTokenId: String, completion: @escaping (_ result: Result<ThreeDS.PostAuthResponse, Error>) -> Void)
    func createApayaSession(clientToken: DecodedClientToken, request: Apaya.CreateSessionAPIRequest, completion: @escaping (_ result: Result<Apaya.CreateSessionAPIResponse, Error>) -> Void)
    func listAdyenBanks(clientToken: DecodedClientToken, request: BankTokenizationSessionRequest, completion: @escaping (_ result: Result<[Bank], Error>) -> Void)
    func poll(clientToken: DecodedClientToken?, url: String, completion: @escaping (_ result: Result<PollingResponse, Error>) -> Void)
    
    func requestPrimerConfigurationWithActions(clientToken: DecodedClientToken, request: ClientSessionUpdateRequest, completion: @escaping (_ result: Result<PrimerAPIConfiguration, Error>) -> Void)
    
    func sendAnalyticsEvents(url: URL, body: Analytics.Service.Request?, completion: @escaping (_ result: Result<Analytics.Service.Response, Error>) -> Void)
    func fetchPayPalExternalPayerInfo(clientToken: DecodedClientToken, payPalExternalPayerInfoRequestBody: PayPal.PayerInfo.Request, completion: @escaping (Result<PayPal.PayerInfo.Response, Error>) -> Void)

    func validateClientToken(request: ClientTokenValidationRequest, completion: @escaping (_ result: Result<SuccessResponse, Error>) -> Void)
    // Create - Resume Payment
    
    func createPayment(clientToken: DecodedClientToken, paymentRequestBody: Payment.CreateRequest, completion: @escaping (_ result: Result<Payment.Response, Error>) -> Void)
    func resumePayment(clientToken: DecodedClientToken, paymentId: String, paymentResumeRequest: Payment.ResumeRequest, completion: @escaping (_ result: Result<Payment.Response, Error>) -> Void)
}

internal class PrimerAPIClient: PrimerAPIClientProtocol {
        
    internal let networkService: NetworkService

    // MARK: - Object lifecycle
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    init(networkService: NetworkService = URLSessionStack()) {
        self.networkService = networkService
    }

    func fetchVaultedPaymentMethods(clientToken: DecodedClientToken, completion: @escaping (_ result: Result<GetVaultedPaymentMethodsResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.fetchVaultedPaymentMethods(clientToken: clientToken)
        networkService.request(endpoint) { (result: Result<GetVaultedPaymentMethodsResponse, Error>) in
            switch result {
            case .success(let vaultedPaymentMethodsResponse):
                AppState.current.selectedPaymentMethodId = vaultedPaymentMethodsResponse.data.first?.id
                completion(.success(vaultedPaymentMethodsResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func exchangePaymentMethodToken(clientToken: DecodedClientToken, paymentMethodId: String, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void) {
        let endpoint = PrimerAPI.exchangePaymentMethodToken(clientToken: clientToken, paymentMethodId: paymentMethodId)
        networkService.request(endpoint) { (result: Result<PaymentMethodToken, Error>) in
            switch result {
            case .success(let paymentInstrument):
                completion(.success(paymentInstrument))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(error))
            }
        }
    }

    func deleteVaultedPaymentMethod(clientToken: DecodedClientToken, id: String, completion: @escaping (_ result: Result<Void, Error>) -> Void) {
        let endpoint = PrimerAPI.deleteVaultedPaymentMethod(clientToken: clientToken, id: id)
        networkService.request(endpoint) { (result: Result<DummySuccess, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(error))
            }
        }
    }

    func fetchConfiguration(clientToken: DecodedClientToken, requestBody: PrimerAPIConfiguration.API.RequestBody?, completion: @escaping (_ result: Result<PrimerAPIConfiguration, Error>) -> Void) {
        let endpoint = PrimerAPI.fetchConfiguration(clientToken: clientToken, requestBody: requestBody)
        networkService.request(endpoint) { (result: Result<PrimerAPIConfiguration, Error>) in
            switch result {
            case .success(let apiConfiguration):
                var imageFiles: [ImageFile] = []
                for pm in (apiConfiguration.paymentMethods ?? []) {
                    var remoteUrl: URL?
                    var base64Data: Data?
                    
                    if let coloredVal = pm.displayMetadata?.button.iconUrl?.coloredUrlStr {
                        if let data = Data(base64Encoded: coloredVal) {
                            base64Data = data
                        } else if let url = URL(string: coloredVal) {
                            remoteUrl = url
                        }
                    }
                    
                    let imageFile = ImageFile(
                        fileName: pm.type,
                        fileExtension: "png",
                        remoteUrl: remoteUrl,
                        base64Data: base64Data)
                    imageFiles.append(imageFile)
                }
                
                let imageManager = ImageManager()
                
                firstly {
                    imageManager.getImages(for: imageFiles)
                }
                .done { imageFiles in
                    for (i, pm) in (apiConfiguration.paymentMethods ?? []).enumerated() {
                        if let imageFile = imageFiles.filter({ $0.fileName == pm.type }).first {
                            apiConfiguration.paymentMethods?[i].imageFiles = PrimerTheme.BaseImageFiles(colored: imageFile, light: nil, dark: nil)
                        }                        
                    }

                    completion(.success(apiConfiguration))
                }
                .catch { err in
                    completion(.success(apiConfiguration))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

//    func createDirectDebitMandate(clientToken: DecodedClientToken, mandateRequest: DirectDebitCreateMandateRequest, completion: @escaping (_ result: Result<DirectDebitCreateMandateResponse, Error>) -> Void) {
//        let endpoint = PrimerAPI.createDirectDebitMandate(clientToken: clientToken, mandateRequest: mandateRequest)
//        networkService.request(endpoint) { (result: Result<DirectDebitCreateMandateResponse, Error>) in
//            switch result {
//            case .success(let apiConfiguration):
//                completion(.success(apiConfiguration))
//            case .failure(let err):
//                completion(.failure(err))
//            }
//        }
//    }

    func createPayPalOrderSession(clientToken: DecodedClientToken, payPalCreateOrderRequest: PayPalCreateOrderRequest, completion: @escaping (_ result: Result<PayPalCreateOrderResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.createPayPalOrderSession(clientToken: clientToken, payPalCreateOrderRequest: payPalCreateOrderRequest)
        networkService.request(endpoint) { (result: Result<PayPalCreateOrderResponse, Error>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func createPayPalBillingAgreementSession(clientToken: DecodedClientToken, payPalCreateBillingAgreementRequest: PayPalCreateBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalCreateBillingAgreementResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.createPayPalSBillingAgreementSession(clientToken: clientToken, payPalCreateBillingAgreementRequest: payPalCreateBillingAgreementRequest)
        networkService.request(endpoint) { (result: Result<PayPalCreateBillingAgreementResponse, Error>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func confirmPayPalBillingAgreement(clientToken: DecodedClientToken, payPalConfirmBillingAgreementRequest: PayPalConfirmBillingAgreementRequest, completion: @escaping (_ result: Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.confirmPayPalBillingAgreement(clientToken: clientToken, payPalConfirmBillingAgreementRequest: payPalConfirmBillingAgreementRequest)
        networkService.request(endpoint) { (result: Result<PayPalConfirmBillingAgreementResponse, Error>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func createKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaCreatePaymentSessionAPIRequest: KlarnaCreatePaymentSessionAPIRequest, completion: @escaping (_ result: Result<KlarnaCreatePaymentSessionAPIResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.createKlarnaPaymentSession(clientToken: clientToken, klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSessionAPIRequest)
        networkService.request(endpoint) { (result: Result<KlarnaCreatePaymentSessionAPIResponse, Error>) in
            switch result {
            case .success(let klarnaCreatePaymentSessionAPIResponse):
                completion(.success(klarnaCreatePaymentSessionAPIResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func createKlarnaCustomerToken(clientToken: DecodedClientToken, klarnaCreateCustomerTokenAPIRequest: CreateKlarnaCustomerTokenAPIRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.createKlarnaCustomerToken(clientToken: clientToken, klarnaCreateCustomerTokenAPIRequest: klarnaCreateCustomerTokenAPIRequest)
        networkService.request(endpoint) { (result: Result<KlarnaCustomerTokenAPIResponse, Error>) in
            switch result {
            case .success(let klarnaCreateCustomerTokenAPIRequest):
                completion(.success(klarnaCreateCustomerTokenAPIRequest))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func finalizeKlarnaPaymentSession(clientToken: DecodedClientToken, klarnaFinalizePaymentSessionRequest: KlarnaFinalizePaymentSessionRequest, completion: @escaping (_ result: Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.finalizeKlarnaPaymentSession(clientToken: clientToken, klarnaFinalizePaymentSessionRequest: klarnaFinalizePaymentSessionRequest)
        networkService.request(endpoint) { (result: Result<KlarnaCustomerTokenAPIResponse, Error>) in
            switch result {
            case .success(let klarnaFinalizePaymentSessionResponse):
                completion(.success(klarnaFinalizePaymentSessionResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func tokenizePaymentMethod(clientToken: DecodedClientToken, paymentMethodTokenizationRequest: TokenizationRequest, completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void) {
        let endpoint = PrimerAPI.tokenizePaymentMethod(clientToken: clientToken, paymentMethodTokenizationRequest: paymentMethodTokenizationRequest)
        networkService.request(endpoint) { (result: Result<PaymentMethodToken, Error>) in
            switch result {
            case .success(let paymentMethodToken):
                completion(.success(paymentMethodToken))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func createApayaSession(
        clientToken: DecodedClientToken,
        request: Apaya.CreateSessionAPIRequest,
        completion: @escaping (Result<Apaya.CreateSessionAPIResponse, Error>) -> Void
    ) {
        let endpoint = PrimerAPI.createApayaSession(clientToken: clientToken, request: request)
        networkService.request(endpoint) { (result: Result<Apaya.CreateSessionAPIResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func listAdyenBanks(clientToken: DecodedClientToken, request: BankTokenizationSessionRequest, completion: @escaping (Result<[Bank], Error>) -> Void) {
        let endpoint = PrimerAPI.listAdyenBanks(clientToken: clientToken, request: request)
        networkService.request(endpoint) { (result: Result<BanksListSessionResponse, Error>) in
            switch result {
            case .success(let res):
                let banks = res.result
                completion(.success(banks))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func poll(
        clientToken: DecodedClientToken?,
        url: String,
        completion: @escaping (_ result: Result<PollingResponse, Error>) -> Void
    ) {
        let endpoint = PrimerAPI.poll(clientToken: clientToken, url: url)
        networkService.request(endpoint) { (result: Result<PollingResponse, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func requestPrimerConfigurationWithActions(clientToken: DecodedClientToken, request: ClientSessionUpdateRequest, completion: @escaping (Result<PrimerAPIConfiguration, Error>) -> Void) {
        let endpoint = PrimerAPI.requestPrimerConfigurationWithActions(clientToken: clientToken, request: request)
        networkService.request(endpoint) { (result: Result<PrimerAPIConfiguration, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func sendAnalyticsEvents(url: URL, body: Analytics.Service.Request?, completion: @escaping (Result<Analytics.Service.Response, Error>) -> Void) {
        let endpoint = PrimerAPI.sendAnalyticsEvents(url: url, body: body)
        networkService.request(endpoint) { (result: Result<Analytics.Service.Response, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func fetchPayPalExternalPayerInfo(clientToken: DecodedClientToken, payPalExternalPayerInfoRequestBody: PayPal.PayerInfo.Request, completion: @escaping (Result<PayPal.PayerInfo.Response, Error>) -> Void) {
        let endpoint = PrimerAPI.fetchPayPalExternalPayerInfo(clientToken: clientToken, payPalExternalPayerInfoRequestBody: payPalExternalPayerInfoRequestBody)
        networkService.request(endpoint) { (result: Result<PayPal.PayerInfo.Response, Error>) in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func validateClientToken(request: ClientTokenValidationRequest, completion: @escaping (Result<SuccessResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.validateClientToken(request: request)
        networkService.request(endpoint) { (result: Result<SuccessResponse, Error>) in
            switch result {
            case .success(let success):
                completion(.success(success))
            case .failure(let error):
                ErrorHandler.handle(error: error)
                completion(.failure(error))
            }
        }
    }

    func createPayment(clientToken: DecodedClientToken, paymentRequestBody: Payment.CreateRequest, completion: @escaping (Result<Payment.Response, Error>) -> Void) {
        let endpoint = PrimerAPI.createPayment(clientToken: clientToken, paymentRequest: paymentRequestBody)
        networkService.request(endpoint) { (result: Result<Payment.Response, Error>) in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    
    func resumePayment(clientToken: DecodedClientToken, paymentId: String, paymentResumeRequest: Payment.ResumeRequest, completion: @escaping (Result<Payment.Response, Error>) -> Void) {
        let endpoint = PrimerAPI.resumePayment(clientToken: clientToken, paymentId: paymentId, paymentResumeRequest: paymentResumeRequest)
        networkService.request(endpoint) { (result: Result<Payment.Response, Error>) in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
}

#endif
