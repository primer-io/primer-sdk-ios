//
//  KlarnaService.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 22/02/2021.
//

struct LocaleData: Codable {
    let countryCode: String
    let currencyCode: String
    let localeCode: String
}

struct OrderItem: Codable {
    let name: String
    let unitAmount: Int
    let quantity: Int
}

struct KlarnaCreatePaymentSessionAPIRequest: Codable {
    let paymentMethodConfigId: String
    let sessionType: String
    let redirectUrl: String
    let totalAmount: Int
    let localeData: LocaleData
    let orderItems: [OrderItem]
}

struct KlarnaSessionCategory: Codable {
    let identifier: String
    let name: String
    let descriptiveAssetUrl: String
    let standardAssetUrl: String
}

struct KlarnaCreatePaymentSessionAPIResponse: Codable {
    let clientToken: String
    let sessionId: String
    let categories: [KlarnaSessionCategory]
    let hppSessionId: String
    let hppRedirectUrl: String
}

struct KlarnaFinalizePaymentSessionRequest: Codable {
    let paymentMethodConfigId: String
    let sessionId: String
}

struct KlarnaSessionOrderLines: Codable {
    let type: String?
    let name: String?
    let quantity: Int?
    let unit_price: Int?
    let total_amount: Int?
    let total_discount_amount: Int?
}

struct KlarnaSessionMerchantUrls: Codable {
    let status_update: String
}

struct KlarnaSessionOptions: Codable {
    let disable_confirmation_modals: Bool
}

struct KlarnaSessionData: Codable {
    let purchase_country: String?
    let purchase_currency: String?
    let locale: String?
    let order_amount: Int?
    let order_lines: [KlarnaSessionOrderLines]?
}

struct KlarnaFinalizePaymentSessionresponse: Codable {
    let sessionData: KlarnaSessionData
}


protocol KlarnaServiceProtocol {
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func finalizePaymentSession(_ completion: @escaping (Result<KlarnaFinalizePaymentSessionresponse, Error>) -> Void)
}


class KlarnaService: KlarnaServiceProtocol {

    @Dependency private(set) var api: PrimerAPIClientProtocol
    @Dependency private(set) var state: AppStateProtocol

    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(KlarnaException.noToken))
        }

        guard let amount = state.settings.amount else {
            return completion(.failure(KlarnaException.noAmount))
        }

        log(logLevel: .info, message: "Klarna amount: \(amount)")

        guard state.settings.currency != nil else {
            return completion(.failure(KlarnaException.noCurrency))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .KLARNA) else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        let body = KlarnaCreatePaymentSessionAPIRequest(
            paymentMethodConfigId: configId,
            sessionType: "HOSTED_PAYMENT_PAGE",
            redirectUrl: "https://primer.io",
            totalAmount: 200,
            localeData: LocaleData(
                countryCode: "GB",
                currencyCode: "GBP",
                localeCode: "en-GB"
            ),
            orderItems: [
                OrderItem(name: "Socks", unitAmount: 200, quantity: 1)
            ]
        )

        log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "createPaymentSession", line: 66)

        api.klarnaCreatePaymentSession(clientToken: clientToken, klarnaCreatePaymentSessionAPIRequest: body) { [weak self] (result) in
            switch result {
            case .failure:
                completion(.failure(KlarnaException.failedApiCall))
            case .success(let response):
                log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createPaymentSession", line: 80)
                self?.state.sessionId = response.sessionId
                completion(.success(response.hppRedirectUrl))
            }
        }
    }

    func finalizePaymentSession(_ completion: @escaping (Result<KlarnaFinalizePaymentSessionresponse, Error>) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(KlarnaException.noToken))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .KLARNA) else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        guard let sessionId = state.sessionId else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        let body = KlarnaFinalizePaymentSessionRequest(paymentMethodConfigId: configId, sessionId: sessionId)

        log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "finalizePaymentSession", line: 66)

        api.klarnaFinalizePaymentSession(clientToken: clientToken, klarnaFinalizePaymentSessionRequest: body) { (result) in
            switch result {
            case .failure:
                completion(.failure(KlarnaException.failedApiCall))
            case .success(let response):
                log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createPaymentSession", line: 80)
                completion(.success(response))
            }
        }
    }
}

