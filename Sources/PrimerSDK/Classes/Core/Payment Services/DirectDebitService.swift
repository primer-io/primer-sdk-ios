//
//  DirectDebitService.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 22/01/2021.
//

#if canImport(UIKit)

internal protocol DirectDebitServiceProtocol {
    func createMandate(_ completion: @escaping (String?, Error?) -> Void)
}

internal class DirectDebitService: DirectDebitServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func createMandate(_ completion: @escaping (String?, Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = ClientTokenService.decodedClientToken else {
            return completion(nil, PrimerError.directDebitSessionFailed)
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .goCardlessMandate) else {
            return completion(nil, PrimerError.directDebitSessionFailed)
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        guard let customer = settings.customer else {
            return completion(nil, PrimerError.userDetailsMissing)
        }

        let mandate = DirectDebitMandate()
        
        let bankDetails = BankDetails(
            iban: mandate.iban,
            bankCode: mandate.sortCode,
            accountNumber: mandate.accountNumber)

        let body = DirectDebitCreateMandateRequest(
            id: configId,
            customer: customer,
            bankDetails: bankDetails)
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.directDebitCreateMandate(clientToken: clientToken, mandateRequest: body) { [weak self] result in
            switch result {
            case .failure:
                completion(nil, PrimerError.directDebitSessionFailed)
            case .success(let response):
                completion(response.mandateId, nil)
            }
        }
    }
}

struct DirectDebitCreateMandateRequest: Codable {
    let id: String
    let customer: Customer
    let bankDetails: BankDetails
}

struct BankDetails: Codable {
    let iban: String?
    let bankCode: String?
    let accountNumber: String?
}

struct DirectDebitCreateMandateResponse: Codable {
    let mandateId: String
    let mandateScheme: String
}

#endif
