//
//  PrimerAPIClient.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

let defaultNetworkService = DefaultNetworkService(
    requestFactory: DefaultNetworkRequestFactory(),
    requestDispatcher: DefaultRequestDispatcher(),
    reportingService: DefaultNetworkReportingService()
)

internal class PrimerAPIClient: PrimerAPIClientProtocol {

    internal let networkService: NetworkService

    // MARK: - Object lifecycle

    init(networkService: NetworkService = defaultNetworkService) {
        self.networkService = networkService
    }

    func genericAPICall(clientToken: DecodedJWTToken, url: URL, completion: @escaping APICompletion<Bool>) {
        let endpoint = PrimerAPI.redirect(clientToken: clientToken, url: url)
        networkService.request(endpoint) { (result: Result<String, Error>) in
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
        execute(endpoint, completion: completion)
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

    func fetchConfiguration(clientToken: DecodedJWTToken,
                            requestParameters: Request.URLParameters.Configuration?,
                            completion: @escaping APICompletion<PrimerAPIConfiguration>) {
        let endpoint = PrimerAPI.fetchConfiguration(clientToken: clientToken, requestParameters: requestParameters)
        execute(endpoint, completion: completion)
    }

    func createPayPalOrderSession(clientToken: DecodedJWTToken,
                                  payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
                                  completion: @escaping APICompletion<Response.Body.PayPal.CreateOrder>) {

        let endpoint = PrimerAPI.createPayPalOrderSession(clientToken: clientToken, payPalCreateOrderRequest: payPalCreateOrderRequest)
        execute(endpoint, completion: completion)
    }

    func createPayPalBillingAgreementSession(clientToken: DecodedJWTToken,
                                             payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
                                             completion: @escaping APICompletion<Response.Body.PayPal.CreateBillingAgreement>) {

        let endpoint = PrimerAPI.createPayPalBillingAgreementSession(clientToken: clientToken,
                                                                     payPalCreateBillingAgreementRequest: payPalCreateBillingAgreementRequest)
        execute(endpoint, completion: completion)
    }

    func confirmPayPalBillingAgreement(clientToken: DecodedJWTToken,
                                       payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement,
                                       completion: @escaping APICompletion<Response.Body.PayPal.ConfirmBillingAgreement>) {
        let endpoint = PrimerAPI.confirmPayPalBillingAgreement(clientToken: clientToken,
                                                               payPalConfirmBillingAgreementRequest: payPalConfirmBillingAgreementRequest)
        execute(endpoint, completion: completion)
    }

    func createKlarnaPaymentSession(
        clientToken: DecodedJWTToken,
        klarnaCreatePaymentSessionAPIRequest: Request.Body.Klarna.CreatePaymentSession,
        completion: @escaping APICompletion<Response.Body.Klarna.PaymentSession>) {
        let endpoint = PrimerAPI.createKlarnaPaymentSession(clientToken: clientToken,
                                                            klarnaCreatePaymentSessionAPIRequest: klarnaCreatePaymentSessionAPIRequest)
        execute(endpoint, completion: completion)
    }

    func createKlarnaCustomerToken(clientToken: DecodedJWTToken,
                                   klarnaCreateCustomerTokenAPIRequest: Request.Body.Klarna.CreateCustomerToken,
                                   completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>) {

        let endpoint = PrimerAPI.createKlarnaCustomerToken(clientToken: clientToken,
                                                           klarnaCreateCustomerTokenAPIRequest: klarnaCreateCustomerTokenAPIRequest)
        execute(endpoint, completion: completion)
    }

    func finalizeKlarnaPaymentSession(clientToken: DecodedJWTToken,
                                      klarnaFinalizePaymentSessionRequest: Request.Body.Klarna.FinalizePaymentSession,
                                      completion: @escaping APICompletion<Response.Body.Klarna.CustomerToken>) {

        let endpoint = PrimerAPI.finalizeKlarnaPaymentSession(clientToken: clientToken,
                                                              klarnaFinalizePaymentSessionRequest: klarnaFinalizePaymentSessionRequest)
        execute(endpoint, completion: completion)
    }

    func listAdyenBanks(
        clientToken: DecodedJWTToken,
        request: Request.Body.Adyen.BanksList,
        completion: @escaping APICompletion<BanksListSessionResponse>) {
        let endpoint = PrimerAPI.listAdyenBanks(clientToken: clientToken, request: request)
        execute(endpoint, completion: completion)
    }

    func listRetailOutlets(clientToken: DecodedJWTToken,
                           paymentMethodId: String,
                           completion: @escaping APICompletion<RetailOutletsList>) {
        let endpoint = PrimerAPI.listRetailOutlets(clientToken: clientToken, paymentMethodId: paymentMethodId)
        execute(endpoint, completion: completion)
    }

    func poll(clientToken: DecodedJWTToken?,
              url: String,
              completion: @escaping APICompletion<PollingResponse>) {
        let endpoint = PrimerAPI.poll(clientToken: clientToken, url: url)
        execute(endpoint, completion: completion)
    }

    func requestPrimerConfigurationWithActions(clientToken: DecodedJWTToken,
                                               request: ClientSessionUpdateRequest,
                                               completion: @escaping APICompletion<PrimerAPIConfiguration>) {

        let endpoint = PrimerAPI.requestPrimerConfigurationWithActions(clientToken: clientToken, request: request)
        execute(endpoint, completion: completion)
    }

    func sendAnalyticsEvents(clientToken: DecodedJWTToken?,
                             url: URL, body: [Analytics.Event]?,
                             completion: @escaping APICompletion<Analytics.Service.Response>) {
        let endpoint = PrimerAPI.sendAnalyticsEvents(clientToken: clientToken, url: url, body: body)
        execute(endpoint, completion: completion)
    }

    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo,
                                      completion: @escaping APICompletion<Response.Body.PayPal.PayerInfo>) {
        let endpoint = PrimerAPI.fetchPayPalExternalPayerInfo(clientToken: clientToken,
                                                              payPalExternalPayerInfoRequestBody: payPalExternalPayerInfoRequestBody)
        execute(endpoint, completion: completion)
    }

    func validateClientToken(request: Request.Body.ClientTokenValidation,
                             completion: @escaping APICompletion<SuccessResponse>) {
        let endpoint = PrimerAPI.validateClientToken(request: request)
        execute(endpoint, completion: completion)
    }

    func createPayment(clientToken: DecodedJWTToken,
                       paymentRequestBody: Request.Body.Payment.Create,
                       completion: @escaping APICompletion<Response.Body.Payment>) {
        let endpoint = PrimerAPI.createPayment(clientToken: clientToken, paymentRequest: paymentRequestBody)
        execute(endpoint, completion: completion)
    }

    func resumePayment(clientToken: DecodedJWTToken,
                       paymentId: String,
                       paymentResumeRequest: Request.Body.Payment.Resume,
                       completion: @escaping APICompletion<Response.Body.Payment>) {
        let endpoint = PrimerAPI.resumePayment(clientToken: clientToken, paymentId: paymentId, paymentResumeRequest: paymentResumeRequest)
        execute(endpoint, completion: completion)
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
        return execute(endpoint, completion: completion)
    }

    func fetchNolSdkSecret(clientToken: DecodedJWTToken,
                           paymentRequestBody: Request.Body.NolPay.NolPaySecretDataRequest,
                           completion: @escaping APICompletion<Response.Body.NolPay.NolPaySecretDataResponse>) {
        let endpoint = PrimerAPI.getNolSdkSecret(clientToken: clientToken, request: paymentRequestBody)
        execute(endpoint, completion: completion)
    }

    func getPhoneMetadata(clientToken: DecodedJWTToken,
                          paymentRequestBody: Request.Body.PhoneMetadata.PhoneMetadataDataRequest,
                          completion: @escaping APICompletion<Response.Body.PhoneMetadata.PhoneMetadataDataResponse>) {
        let endpoint = PrimerAPI.getPhoneMetadata(clientToken: clientToken,
                                                  request: paymentRequestBody)
        execute(endpoint, completion: completion)
    }
}

extension PrimerAPIClient {

    @discardableResult
    private func execute<T>(_ endpoint: Endpoint, completion: @escaping APICompletion<T>) -> PrimerCancellable? where T: Decodable {
        networkService.request(endpoint) { (result: Result<T, Error>) in
            switch result {
            case .success(let result):
                completion(.success(result))
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(.failure(error))
            }
        }
    }

}
