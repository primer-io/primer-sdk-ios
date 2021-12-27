//
//  DirectDebitService.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 22/01/2021.
//

#if canImport(UIKit)

internal protocol DirectDebitServiceProtocol {
    func createMandate(_ directDebitMandate: DirectDebitMandate, completion: @escaping (Error?) -> Void)
}

internal class DirectDebitService: DirectDebitServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func createMandate(_ directDebitMandate: DirectDebitMandate, completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerInternalError.invalidClientToken
            _ = ErrorHandler.shared.handle(error: err)
            completion(err)
            return
        }

        guard let configId = state.primerConfiguration?.getConfigId(for: .goCardlessMandate) else {
            let err = PaymentError.invalidValue(key: "configId", value: state.primerConfiguration?.getConfigId(for: .goCardlessMandate))
            _ = ErrorHandler.shared.handle(error: err)
            completion(err)
            return
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        guard let customer = settings.customer else {
            let err = PaymentError.invalidValue(key: "settings.customer", value: nil)
            _ = ErrorHandler.shared.handle(error: err)
            completion(err)
            return
        }
        
        let bankDetails = BankDetails(
            iban: directDebitMandate.iban,
            bankCode: directDebitMandate.sortCode,
            accountNumber: directDebitMandate.accountNumber)

        let body = DirectDebitCreateMandateRequest(
            id: configId,
            customer: customer,
            bankDetails: bankDetails)
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.directDebitCreateMandate(clientToken: clientToken, mandateRequest: body) { result in
            switch result {
            case .failure(let err):
                let containerErr = PaymentError.failedToCreateSession(error: err)
                _ = ErrorHandler.shared.handle(error: containerErr)
                completion(containerErr)
            case .success(let response):
                completion(nil)
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
