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
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(err)
            return
        }

        guard let configId = state.apiConfiguration?.getConfigId(for: .goCardlessMandate) else {
            let err = PrimerError.invalidValue(key: "configId", value: state.apiConfiguration?.getConfigId(for: .goCardlessMandate), userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(err)
            return
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        guard let customer = settings.customer else {
            let err = PrimerError.invalidValue(key: "settings.customer", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
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

        api.createDirectDebitMandate(clientToken: clientToken, mandateRequest: body) { result in
            switch result {
            case .failure(let err):
                let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: containerErr)
                completion(containerErr)
            case .success:
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
