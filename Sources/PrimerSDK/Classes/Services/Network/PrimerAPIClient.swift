//
//  PrimerAPIClient.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

protocol PrimerAPIClientProtocol: PrimerAPIClientAnalyticsProtocol {

    func genericAPICall(clientToken: DecodedJWTToken,
                        url: URL,
                        completion: @escaping (_ result: Result<Bool, Error>) -> Void)

    func validateClientToken(
        request: Request.Body.ClientTokenValidation,
        completion: @escaping (_ result: Result<SuccessResponse, Error>) -> Void)
    func fetchConfiguration(
        clientToken: DecodedJWTToken,
        requestParameters: Request.URLParameters.Configuration?,
        completion: @escaping (_ result: Result<Response.Body.Configuration, Error>) -> Void)

    func fetchVaultedPaymentMethods(
        clientToken: DecodedJWTToken,
        completion: @escaping (_ result: Result<Response.Body.VaultedPaymentMethods, Error>) -> Void)
    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken) -> Promise<Response.Body.VaultedPaymentMethods>

    func deleteVaultedPaymentMethod(
        clientToken: DecodedJWTToken,
        id: String,
        completion: @escaping (_ result: Result<Void, Error>) -> Void)

    // PayPal
    func createPayPalOrderSession(
        clientToken: DecodedJWTToken,
        payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
        completion: @escaping (_ result: Result<Response.Body.PayPal.CreateOrder, Error>) -> Void)
    func createPayPalBillingAgreementSession(
        clientToken: DecodedJWTToken,
        payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
        completion: @escaping (_ result: Result<Response.Body.PayPal.CreateBillingAgreement, Error>) -> Void)
    func confirmPayPalBillingAgreement(
        clientToken: DecodedJWTToken,
        payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement,
        completion: @escaping (_ result: Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void)

    // Klarna
    func createKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession,
        completion: @escaping (_ result: Result<Response.Body.Klarna.PaymentSession, Error>) -> Void)
    func createKlarnaCustomerToken(
        clientToken: DecodedJWTToken,
        klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken,
        completion: @escaping (_ result: Result<Response.Body.Klarna.CustomerToken, Error>) -> Void)
    func finalizeKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession,
        completion: @escaping (_ result: Result<Response.Body.Klarna.CustomerToken, Error>) -> Void)

    // Tokenization
    func tokenizePaymentMethod(
        clientToken: DecodedJWTToken,
        tokenizationRequestBody: Request.Body.Tokenization,
        completion: @escaping (_ result: Result<PrimerPaymentMethodTokenData, Error>) -> Void)
    func exchangePaymentMethodToken(
        clientToken: DecodedJWTToken,
        vaultedPaymentMethodId: String,
        vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?,
        completion: @escaping (_ result: Result<PrimerPaymentMethodTokenData, Error>) -> Void)

    // 3DS
    func begin3DSAuth(clientToken: DecodedJWTToken,
                      paymentMethodTokenData: PrimerPaymentMethodTokenData,
                      threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                      completion: @escaping (_ result: Result<ThreeDS.BeginAuthResponse, Error>) -> Void)
    func continue3DSAuth(
        clientToken: DecodedJWTToken,
        threeDSTokenId: String,
        continueInfo: ThreeDS.ContinueInfo,
        completion: @escaping (_ result: Result<ThreeDS.PostAuthResponse, Error>) -> Void)

    // Apaya
    func createApayaSession(
        clientToken: DecodedJWTToken,
        request: Request.Body.Apaya.CreateSession,
        completion: @escaping (_ result: Result<Response.Body.Apaya.CreateSession, Error>) -> Void)

    // Adyen Banks List
    func listAdyenBanks(
        clientToken: DecodedJWTToken,
        request: Request.Body.Adyen.BanksList,
        completion: @escaping (_ result: Result<[Response.Body.Adyen.Bank], Error>) -> Void)

    // Retail Outlets
    func listRetailOutlets(
        clientToken: DecodedJWTToken,
        paymentMethodId: String,
        completion: @escaping (_ result: Result<RetailOutletsList, Error>) -> Void)

    func poll(clientToken: DecodedJWTToken?,
              url: String,
              completion: @escaping (_ result: Result<PollingResponse, Error>) -> Void)

    func requestPrimerConfigurationWithActions(clientToken: DecodedJWTToken,
                                               request: ClientSessionUpdateRequest,
                                               completion: @escaping (_ result: Result<PrimerAPIConfiguration, Error>) -> Void)

    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo,
                                      completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void)

    // Payment
    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create,
        completion: @escaping (_ result: Result<Response.Body.Payment, Error>) -> Void)
    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume,
        completion: @escaping (_ result: Result<Response.Body.Payment, Error>) -> Void)

    func testFinalizePolling(
        clientToken: DecodedJWTToken,
        testId: String,
        completion: @escaping (_ result: Result<Void, Error>) -> Void)

    // NolPay
    func fetchNolSdkSecret(clientToken: DecodedJWTToken,
                           paymentRequestBody: Request.Body.NolPay.NolPaySecretDataRequest,
                           completion: @escaping (_ result: Result<Response.Body.NolPay.NolPaySecretDataResponse, Error>) -> Void)

    // Phone validation
    func getPhoneMetadata(clientToken: DecodedJWTToken,
                          paymentRequestBody: Request.Body.PhoneMetadata.PhoneMetadataDataRequest,
                          completion: @escaping (Result<Response.Body.PhoneMetadata.PhoneMetadataDataResponse, Error>) -> Void)

}

internal class PrimerAPIClient: PrimerAPIClientProtocol {
    
    internal let networkService: NetworkService
    
    // MARK: - Object lifecycle
    
    init(networkService: NetworkService = URLSessionStack()) {
        self.networkService = networkService
    }
    
    func genericAPICall(clientToken: DecodedJWTToken, url: URL, completion: @escaping (Result<Bool, Error>) -> Void) {
        let endpoint = PrimerAPI.redirect(clientToken: clientToken, url: url)
        networkService.request(endpoint) { (result: Result<SuccessResponse, Error>) in
            
            switch result {
                
            case .success:
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken,
                                    completion: @escaping (_ result: Result<Response.Body.VaultedPaymentMethods, Error>) -> Void) {
        let endpoint = PrimerAPI.fetchVaultedPaymentMethods(clientToken: clientToken)
        networkService.request(endpoint) { (result: Result<Response.Body.VaultedPaymentMethods, Error>) in
            switch result {
            case .success(let vaultedPaymentMethodsResponse):
                AppState.current.selectedPaymentMethodId = vaultedPaymentMethodsResponse.data.first?.id
                completion(.success(vaultedPaymentMethodsResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func exchangePaymentMethodToken(
        clientToken: DecodedJWTToken,
        vaultedPaymentMethodId: String,
        vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?,
        completion: @escaping (_ result: Result<PrimerPaymentMethodTokenData, Error>) -> Void
    ) {
        let endpoint = PrimerAPI.exchangePaymentMethodToken(clientToken: clientToken,
                                                            vaultedPaymentMethodId: vaultedPaymentMethodId,
                                                            vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData)
        networkService.request(endpoint) { (result: Result<PrimerPaymentMethodTokenData, Error>) in
            switch result {
            case .success(let paymentInstrument):
                completion(.success(paymentInstrument))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(error))
            }
        }
    }
    
    func deleteVaultedPaymentMethod(clientToken: DecodedJWTToken, id: String, completion: @escaping (_ result: Result<Void, Error>) -> Void) {
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
    
    func fetchConfiguration(
        clientToken: DecodedJWTToken,
        requestParameters: Request.URLParameters.Configuration?,
        completion: @escaping (_ result: Result<PrimerAPIConfiguration, Error>) -> Void) {
            let endpoint = PrimerAPI.fetchConfiguration(clientToken: clientToken, requestParameters: requestParameters)
            networkService.request(endpoint) { (result: Result<PrimerAPIConfiguration, Error>) in
                switch result {
                case .success(let apiConfiguration):
                    var imageFiles: [ImageFile] = []
                    
                    for paymentMethod in (apiConfiguration.paymentMethods ?? []) {
                        
                        var coloredImageFile: ImageFile
                        if let coloredVal = paymentMethod.displayMetadata?.button.iconUrl?.coloredUrlStr {
                            var remoteUrl: URL?
                            var base64Data: Data?
                            
                            if let data = Data(base64Encoded: coloredVal) {
                                base64Data = data
                            } else if let url = URL(string: coloredVal) {
                                remoteUrl = url
                            }
                            
                            coloredImageFile = ImageFile(
                                fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-colored",
                                fileExtension: "png",
                                remoteUrl: remoteUrl,
                                base64Data: base64Data)
                            
                        } else {
                            coloredImageFile = ImageFile(
                                fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-colored",
                                fileExtension: "png",
                                remoteUrl: nil,
                                base64Data: nil)
                        }
                        imageFiles.append(coloredImageFile)
                        
                        var lightImageFile: ImageFile
                        if let lightVal = paymentMethod.displayMetadata?.button.iconUrl?.lightUrlStr {
                            var remoteUrl: URL?
                            var base64Data: Data?
                            
                            if let data = Data(base64Encoded: lightVal) {
                                base64Data = data
                            } else if let url = URL(string: lightVal) {
                                remoteUrl = url
                            }
                            
                            lightImageFile = ImageFile(
                                fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-light",
                                fileExtension: "png",
                                remoteUrl: remoteUrl,
                                base64Data: base64Data)
                            
                        } else {
                            lightImageFile = ImageFile(
                                fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-light",
                                fileExtension: "png",
                                remoteUrl: nil,
                                base64Data: nil)
                        }
                        imageFiles.append(lightImageFile)
                        
                        var darkImageFile: ImageFile
                        if let darkVal = paymentMethod.displayMetadata?.button.iconUrl?.darkUrlStr {
                            var remoteUrl: URL?
                            var base64Data: Data?
                            
                            if let data = Data(base64Encoded: darkVal) {
                                base64Data = data
                            } else if let url = URL(string: darkVal) {
                                remoteUrl = url
                            }
                            
                            darkImageFile = ImageFile(
                                fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-dark",
                                fileExtension: "png",
                                remoteUrl: remoteUrl,
                                base64Data: base64Data)
                            
                        } else {
                            darkImageFile = ImageFile(
                                fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-dark",
                                fileExtension: "png",
                                remoteUrl: nil,
                                base64Data: nil)
                        }
                        imageFiles.append(darkImageFile)
                    }
                    
                    let imageManager = ImageManager()
                    
                    firstly {
                        imageManager.getImages(for: imageFiles)
                    }
                    .done { imageFiles in
                        for (index, paymentMethod) in (apiConfiguration.paymentMethods ?? []).enumerated() {
                            let paymentMethodImageFiles = imageFiles.filter { $0.fileName.contains(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-")) }
                            if paymentMethodImageFiles.isEmpty {
                                continue
                            }
                            
                            let coloredImageFile = paymentMethodImageFiles
                                .filter({ $0.fileName.contains("dark") == false && $0.fileName.contains("light") == false }).first
                            let darkImageFile = paymentMethodImageFiles
                                .filter({ $0.fileName.contains("dark") == true }).first
                            let lightImageFile = paymentMethodImageFiles
                                .filter({ $0.fileName.contains("light") == true }).first
                            
                            let baseImage = PrimerTheme.BaseImage(
                                colored: coloredImageFile?.image,
                                light: lightImageFile?.image,
                                dark: darkImageFile?.image)
                            apiConfiguration.paymentMethods?[index].baseLogoImage = baseImage
                        }
                        
                        completion(.success(apiConfiguration))
                    }
                    .catch { _ in
                        completion(.success(apiConfiguration))
                    }
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }
    
    func createPayPalOrderSession(clientToken: DecodedJWTToken,
                                  payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
                                  completion: @escaping (_ result: Result<Response.Body.PayPal.CreateOrder, Error>) -> Void) {
        
        let endpoint = PrimerAPI.createPayPalOrderSession(clientToken: clientToken, payPalCreateOrderRequest: payPalCreateOrderRequest)
        networkService.request(endpoint) { (result: Result<Response.Body.PayPal.CreateOrder, Error>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func createPayPalBillingAgreementSession(clientToken: DecodedJWTToken,
                                             payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
                                             completion: @escaping (_ result: Result<Response.Body.PayPal.CreateBillingAgreement, Error>) -> Void) {
        
        let endpoint = PrimerAPI.createPayPalBillingAgreementSession(clientToken: clientToken, payPalCreateBillingAgreementRequest: payPalCreateBillingAgreementRequest)
        networkService.request(endpoint) { (result: Result<Response.Body.PayPal.CreateBillingAgreement, Error>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func confirmPayPalBillingAgreement(clientToken: DecodedJWTToken,
                                       payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement,
                                       completion: @escaping (_ result: Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void) {
        let endpoint = PrimerAPI.confirmPayPalBillingAgreement(clientToken: clientToken, payPalConfirmBillingAgreementRequest: payPalConfirmBillingAgreementRequest)
        networkService.request(endpoint) { (result: Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) in
            switch result {
            case .success(let payPalCreateOrderResponse):
                completion(.success(payPalCreateOrderResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    func createKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession,
        completion: @escaping (_ result: Result<Response.Body.Klarna.PaymentSession, Error>) -> Void) {
            let endpoint = PrimerAPI.createKlarnaPaymentSession(clientToken: clientToken, klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSessionAPIRequest)
            networkService.request(endpoint) { (result: Result<Response.Body.Klarna.PaymentSession, Error>) in
                switch result {
                case .success(let klarnaCreatePaymentSessionAPIResponse):
                    completion(.success(klarnaCreatePaymentSessionAPIResponse))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }

    func createKlarnaCustomerToken(clientToken: DecodedJWTToken,
                                   klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken,
                                   completion: @escaping (_ result: Result<Response.Body.Klarna.CustomerToken, Error>) -> Void) {

        let endpoint = PrimerAPI.createKlarnaCustomerToken(clientToken: clientToken, klarnaCreateCustomerTokenAPIRequest: klarnaCreateCustomerTokenAPIRequest)
        networkService.request(endpoint) { (result: Result<Response.Body.Klarna.CustomerToken, Error>) in
            switch result {
            case .success(let klarnaCreateCustomerTokenAPIRequest):
                completion(.success(klarnaCreateCustomerTokenAPIRequest))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func finalizeKlarnaPaymentSession(clientToken: DecodedJWTToken,
                                      klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession,
                                      completion: @escaping (_ result: Result<Response.Body.Klarna.CustomerToken, Error>) -> Void) {

        let endpoint = PrimerAPI.finalizeKlarnaPaymentSession(clientToken: clientToken, klarnaFinalizePaymentSessionRequest: klarnaFinalizePaymentSessionRequest)
        networkService.request(endpoint) { (result: Result<Response.Body.Klarna.CustomerToken, Error>) in
            switch result {
            case .success(let klarnaFinalizePaymentSessionResponse):
                completion(.success(klarnaFinalizePaymentSessionResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func createApayaSession(
        clientToken: DecodedJWTToken,
        request: Request.Body.Apaya.CreateSession,
        completion: @escaping (Result<Response.Body.Apaya.CreateSession, Error>) -> Void
    ) {
        let endpoint = PrimerAPI.createApayaSession(clientToken: clientToken, request: request)
        networkService.request(endpoint) { (result: Result<Response.Body.Apaya.CreateSession, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func listAdyenBanks(
        clientToken: DecodedJWTToken,
        request: Request.Body.Adyen.BanksList,
        completion: @escaping (Result<[Response.Body.Adyen.Bank], Error>) -> Void) {
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

    func listRetailOutlets(clientToken: DecodedJWTToken,
                           paymentMethodId: String,
                           completion: @escaping (Result<RetailOutletsList, Error>) -> Void) {
        let endpoint = PrimerAPI.listRetailOutlets(clientToken: clientToken, paymentMethodId: paymentMethodId)
        networkService.request(endpoint) { (result: Result<RetailOutletsList, Error>) in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func poll(
        clientToken: DecodedJWTToken?,
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

    func requestPrimerConfigurationWithActions(clientToken: DecodedJWTToken,
                                               request: ClientSessionUpdateRequest,
                                               completion: @escaping (Result<PrimerAPIConfiguration, Error>) -> Void) {

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

    func sendAnalyticsEvents(clientToken: DecodedJWTToken?,
                             url: URL, body: [Analytics.Event]?,
                             completion: @escaping (Result<Analytics.Service.Response, Error>) -> Void) {

        let endpoint = PrimerAPI.sendAnalyticsEvents(clientToken: clientToken, url: url, body: body)
        networkService.request(endpoint) { (result: Result<Analytics.Service.Response, Error>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo,
                                      completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void) {

        let endpoint = PrimerAPI.fetchPayPalExternalPayerInfo(clientToken: clientToken,
                                                              payPalExternalPayerInfoRequestBody: payPalExternalPayerInfoRequestBody)
        networkService.request(endpoint) { (result: Result<Response.Body.PayPal.PayerInfo, Error>) in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func validateClientToken(request: Request.Body.ClientTokenValidation, completion: @escaping (Result<SuccessResponse, Error>) -> Void) {
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

    func createPayment(clientToken: DecodedJWTToken, paymentRequestBody: Request.Body.Payment.Create, completion: @escaping (Result<Response.Body.Payment, Error>) -> Void) {
        let endpoint = PrimerAPI.createPayment(clientToken: clientToken, paymentRequest: paymentRequestBody)
        networkService.request(endpoint) { (result: Result<Response.Body.Payment, Error>) in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func resumePayment(clientToken: DecodedJWTToken, paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume, completion: @escaping (Result<Response.Body.Payment, Error>) -> Void) {
        let endpoint = PrimerAPI.resumePayment(clientToken: clientToken, paymentId: paymentId, paymentResumeRequest: paymentResumeRequest)
        networkService.request(endpoint) { (result: Result<Response.Body.Payment, Error>) in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func testFinalizePolling(clientToken: DecodedJWTToken, testId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let endpoint = PrimerAPI.testFinalizePolling(clientToken: clientToken, testId: testId)
        networkService.request(endpoint) { (result: Result<Response.Body.Payment, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func fetchNolSdkSecret(clientToken: DecodedJWTToken,
                           paymentRequestBody: Request.Body.NolPay.NolPaySecretDataRequest,
                           completion: @escaping (Result<Response.Body.NolPay.NolPaySecretDataResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.getNolSdkSecret(clientToken: clientToken, request: paymentRequestBody)
        networkService.request(endpoint) { (result: Result<Response.Body.NolPay.NolPaySecretDataResponse, Error>) in
            switch result {

            case .success(let nolSdkSecret):
                completion(.success(nolSdkSecret))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func getPhoneMetadata(clientToken: DecodedJWTToken,
                          paymentRequestBody: Request.Body.PhoneMetadata.PhoneMetadataDataRequest,
                          completion: @escaping (Result<Response.Body.PhoneMetadata.PhoneMetadataDataResponse, Error>) -> Void) {

        let endpoint = PrimerAPI.getPhoneMetadata(clientToken: clientToken,
                                                  request: paymentRequestBody)
        networkService.request(endpoint) { (result: Result<Response.Body.PhoneMetadata.PhoneMetadataDataResponse, Error>) in
            switch result {

            case .success(let phoneMetadataResponse):
                completion(.success(phoneMetadataResponse))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
}
