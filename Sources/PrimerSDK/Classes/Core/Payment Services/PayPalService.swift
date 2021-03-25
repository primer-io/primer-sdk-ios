import Foundation

#if canImport(UIKit)

protocol PayPalServiceProtocol {
    func startOrderSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void)
}

class PayPalService: PayPalServiceProtocol {

    @Dependency private(set) var api: PrimerAPIClientProtocol
    @Dependency private(set) var state: AppStateProtocol

    private func prepareUrlAndTokenAndId(path: String) -> (DecodedClientToken, URL, String)? {
        guard let clientToken = state.decodedClientToken else {
            return nil
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .PAYPAL) else {
            return nil
        }

        guard let coreURL = clientToken.coreUrl else {
            return nil
        }

        guard let url = URL(string: "\(coreURL)\(path)") else {
            return nil
        }

        return (clientToken, url, configId)
    }

    func startOrderSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .PAYPAL) else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }

        guard let amount = state.settings.amount else {
            fatalError("Paypal checkout requires amount value!")
        }

        guard let currency = state.settings.currency else {
            fatalError("Paypal checkout requires currency value!")
        }

        guard let urlScheme = state.settings.urlScheme else {
            fatalError("Paypal checkout requires URL Scheme value!")
        }

        let body = PayPalCreateOrderRequest(
            paymentMethodConfigId: configId,
            amount: amount,
            currencyCode: currency,
            returnUrl: urlScheme,
            cancelUrl: urlScheme
        )

        api.payPalStartOrderSession(clientToken: clientToken, payPalCreateOrderRequest: body) { [weak self] (result) in
            switch result {
            case .failure:
                completion(.failure(PrimerError.PayPalSessionFailed))
            case .success(let response):
                self?.state.orderId = response.orderId
                completion(.success(response.approvalUrl))
            }
        }
    }

    func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .PAYPAL) else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }

        guard let urlScheme = state.settings.urlScheme else {
            fatalError("Paypal checkout requires URL Scheme value!")
        }

        let body = PayPalCreateBillingAgreementRequest(
            paymentMethodConfigId: configId,
            returnUrl: urlScheme,
            cancelUrl: urlScheme
        )

        api.payPalStartBillingAgreementSession(clientToken: clientToken, payPalCreateBillingAgreementRequest: body) { [weak self] (result) in
            switch result {
            case .failure:
                completion(.failure(PrimerError.PayPalSessionFailed))
            case .success(let config):
                self?.state.billingAgreementToken = config.tokenId
                completion(.success(config.approvalUrl))
            }
        }
    }

    func confirmBillingAgreement(_ completion: @escaping (Result<PayPalConfirmBillingAgreementResponse, Error>) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .PAYPAL) else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }

        guard let tokenId = state.billingAgreementToken else {
            return completion(.failure(PrimerError.PayPalSessionFailed))
        }

        let body = PayPalConfirmBillingAgreementRequest(paymentMethodConfigId: configId, tokenId: tokenId)

        api.payPalConfirmBillingAgreement(clientToken: clientToken, payPalConfirmBillingAgreementRequest: body) { [weak self] (result) in
            switch result {
            case .failure:
                completion(.failure(PrimerError.PayPalSessionFailed))
            case .success(let response):
                self?.state.confirmedBillingAgreement = response
                completion(.success(response))
            }
        }
    }

}

#endif
