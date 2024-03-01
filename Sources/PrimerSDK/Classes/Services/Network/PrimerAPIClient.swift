//
//  PrimerAPIClient.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

internal class PrimerAPIClient: PrimerAPIClientProtocol {

    internal let networkService: NetworkService

    // MARK: - Object lifecycle

    init(networkService: NetworkService = URLSessionStack()) {
        self.networkService = networkService
    }

    func genericAPICall(clientToken: DecodedJWTToken, url: URL, completion: @escaping APICompletion<Bool>) {
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
                                    completion: @escaping APICompletion<Response.Body.VaultedPaymentMethods>) {
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
        completion: @escaping APICompletion<PrimerPaymentMethodTokenData>
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

    func deleteVaultedPaymentMethod(clientToken: DecodedJWTToken, id: String, completion: @escaping APICompletion<Void>) {
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
        completion: @escaping APICompletion<PrimerAPIConfiguration>) {
        let endpoint = PrimerAPI.fetchConfiguration(clientToken: clientToken, requestParameters: requestParameters)
        networkService.request(endpoint) { (result: Result<PrimerAPIConfiguration, Error>) in
            switch result {
            case .success(let apiConfiguration):
                completion(.success(apiConfiguration))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func createPayPalOrderSession(clientToken: DecodedJWTToken,
                                  payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
                                  completion: @escaping APICompletion<Response.Body.PayPal.CreateOrder>) {

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
                                             completion: @escaping APICompletion<Response.Body.PayPal.CreateBillingAgreement>) {

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
                                       completion: @escaping APICompletion<Response.Body.PayPal.ConfirmBillingAgreement>) {
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
        completion: @escaping APICompletion<Response.Body.Klarna.CreatePaymentSession>) {
        let endpoint = PrimerAPI.createKlarnaPaymentSession(clientToken: clientToken, klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSessionAPIRequest)
        networkService.request(endpoint) { (result: Result<Response.Body.Klarna.CreatePaymentSession, Error>) in
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
                                   completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>) {

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
                                      completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>) {

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

    func createApayaSession(clientToken: DecodedJWTToken,
                            request: Request.Body.Apaya.CreateSession,
                            completion: @escaping APICompletion<Response.Body.Apaya.CreateSession>) {
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

    func listAdyenBanks(clientToken: DecodedJWTToken,
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
                           completion: @escaping APICompletion<RetailOutletsList>) {
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

    func poll(clientToken: DecodedJWTToken?,
              url: String,
              completion: @escaping APICompletion<PollingResponse>) {
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
                                               completion: @escaping APICompletion<PrimerAPIConfiguration>) {

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
                             completion: @escaping APICompletion<Analytics.Service.Response>) {

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
                                      completion: @escaping APICompletion<Response.Body.PayPal.PayerInfo>) {

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

    func validateClientToken(request: Request.Body.ClientTokenValidation, 
                             completion: @escaping APICompletion<SuccessResponse>) {
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

    func createPayment(clientToken: DecodedJWTToken, 
                       paymentRequestBody: Request.Body.Payment.Create,
                       completion: @escaping APICompletion<Response.Body.Payment>) {
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

    func resumePayment(clientToken: DecodedJWTToken, 
                       paymentId: String,
                       paymentResumeRequest: Request.Body.Payment.Resume,
                       completion: @escaping APICompletion<Response.Body.Payment>) {
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

    func testFinalizePolling(clientToken: DecodedJWTToken, testId: String, completion: @escaping APICompletion<Void>) {
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

    func listCardNetworks(clientToken: DecodedJWTToken,
                          bin: String,
                          completion: @escaping APICompletion<Response.Body.Bin.Networks>) -> PrimerCancellable? {
        let endpoint = PrimerAPI.listCardNetworks(clientToken: clientToken, bin: bin)
        return networkService.request(endpoint) { (result: Result<Response.Body.Bin.Networks, Error>) in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func fetchNolSdkSecret(clientToken: DecodedJWTToken,
                           paymentRequestBody: Request.Body.NolPay.NolPaySecretDataRequest,
                           completion: @escaping APICompletion<Response.Body.NolPay.NolPaySecretDataResponse>) {
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
                          completion: @escaping APICompletion<Response.Body.PhoneMetadata.PhoneMetadataDataResponse>) {

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
