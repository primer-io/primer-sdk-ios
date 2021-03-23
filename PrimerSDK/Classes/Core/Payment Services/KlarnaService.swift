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

public struct OrderItem: Codable {
    public let name: String
    public let unitAmount: Int
    public let quantity: Int
    
    public init(
        name: String,
        unitAmount: Int,
        quantity: Int
    ) {
        self.name = name
        self.unitAmount = unitAmount
        self.quantity = quantity
    }
}

// MARK: CREATE PAYMENT SESSION DATA MODELS

struct KlarnaCreatePaymentSessionAPIRequest: Codable {
    let paymentMethodConfigId: String
    let sessionType: String
    let redirectUrl: String
    let totalAmount: Int
    let localeData: LocaleData
    let orderItems: [OrderItem]
}

struct KlarnaCreatePaymentSessionAPIResponse: Codable {
    let clientToken: String
    let sessionId: String
    let categories: [KlarnaSessionCategory]
    let hppSessionId: String
    let hppRedirectUrl: String
}

// MARK: CREATE CUSTOMER TOKEN DATA MODELS

struct CreateKlarnaCustomerTokenAPIRequest: Codable {
    let paymentMethodConfigId: String
    let sessionId: String
    let authorizationToken: String
    let description: String
    let localeData: LocaleData
}

struct KlarnaCustomerTokenAPIResponse: Codable {
    let customerTokenId: String
    let sessionData: KlarnaSessionData
}

// MARK: FINALIZE PAYMENT SESSION DATA MODELS

struct KlarnaFinalizePaymentSessionRequest: Codable {
    let paymentMethodConfigId: String
    let sessionId: String
}

struct KlarnaSessionCategory: Codable {
    let identifier: String
    let name: String
    let descriptiveAssetUrl: String
    let standardAssetUrl: String
}

struct KlarnaSessionOrderLines: Codable {
    let type: String?
    let name: String?
    let quantity: Int?
    let unitPrice: Int?
    let totalAmount: Int?
    let totalDiscountAmount: Int?
}

struct KlarnaSessionMerchantUrls: Codable {
    let statusUpdate: String
}

struct KlarnaSessionOptions: Codable {
    let disableConfirmationModals: Bool
}

struct KlarnaSessionData: Codable {
    let purchaseCountry: String?
    let purchaseCurrency: String?
    let locale: String?
    let orderAmount: Int?
    let orderLines: [KlarnaSessionOrderLines]
    let billingAddress: KlarnaBillingAddress?
}

struct KlarnaBillingAddress: Codable {
    let addressLine1: String?
    let addressLine2: String?
    let addressLine3: String?
    let city: String?
    let countryCode: String?
    let email: String?
    let firstName: String?
    let lastName: String?
    let phoneNumber: String?
    let postalCode: String?
    let state: String?
    let title: String?
}

struct KlarnaFinalizePaymentSessionresponse: Codable {
    let sessionData: KlarnaSessionData
}


protocol KlarnaServiceProtocol {
    func createPaymentSession(_ completion: @escaping (Result<String, Error>) -> Void)
    func createKlarnaCustomerToken(_ completion: @escaping (Result<String, Error>) -> Void)
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
        
        guard let countryCode = self.state.settings.countryCode else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        guard let currency = self.state.settings.currency else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        let body = KlarnaCreatePaymentSessionAPIRequest(
            paymentMethodConfigId: configId,
            sessionType: "HOSTED_PAYMENT_PAGE",
            redirectUrl: "https://primer.io",
            totalAmount: amount,
            localeData: LocaleData(
                countryCode: countryCode.rawValue,
                currencyCode: currency.rawValue,
                localeCode: countryCode.klarnaLocaleCode
            ),
            orderItems: self.state.settings.orderItems
        )

        log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "createPaymentSession")

        api.klarnaCreatePaymentSession(clientToken: clientToken, klarnaCreatePaymentSessionAPIRequest: body) { [weak self] (result) in
            switch result {
            case .failure:
                completion(.failure(KlarnaException.failedApiCall))
            case .success(let response):
                log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createPaymentSession")
                self?.state.sessionId = response.sessionId
                completion(.success(response.hppRedirectUrl))
            }
        }
    }
    
    func createKlarnaCustomerToken(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(KlarnaException.noToken))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .KLARNA) else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        guard let authorizationToken = self.state.authorizationToken else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        guard let sessionId = self.state.sessionId else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        guard let countryCode = self.state.settings.countryCode else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }
        
        guard let currency = self.state.settings.currency else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        let body = CreateKlarnaCustomerTokenAPIRequest(
            paymentMethodConfigId: configId,
            sessionId: sessionId,
            authorizationToken: authorizationToken,
            description: "primer",
            localeData: LocaleData(
                countryCode: countryCode.rawValue,
                currencyCode: currency.rawValue,
                localeCode: countryCode.klarnaLocaleCode
            )
        )
        
        api.klarnaCreateCustomerToken(clientToken: clientToken, klarnaCreateCustomerTokenAPIRequest: body) { (result) in
            switch result {
            case .failure:
                completion(.failure(KlarnaException.failedApiCall))
            case .success(let response):
                log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createCustomerToken")
                completion(.success(response.customerTokenId))
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

        log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "finalizePaymentSession")

        api.klarnaFinalizePaymentSession(clientToken: clientToken, klarnaFinalizePaymentSessionRequest: body) { (result) in
            switch result {
            case .failure:
                completion(.failure(KlarnaException.failedApiCall))
            case .success(let response):
                log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createPaymentSession")
                completion(.success(response))
            }
        }
    }
}

