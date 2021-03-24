//
//  DirectDebitService.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 22/01/2021.
//

#if canImport(UIKit)

protocol DirectDebitServiceProtocol {
    func createMandate(_ completion: @escaping (Error?) -> Void)
}

class DirectDebitService: DirectDebitServiceProtocol {
    
    @Dependency private(set) var api: PrimerAPIClientProtocol
    @Dependency private(set) var state: AppStateProtocol
    
    func createMandate(_ completion: @escaping (Error?) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.DirectDebitSessionFailed)
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .GOCARDLESS_MANDATE) else {
            return completion(PrimerError.DirectDebitSessionFailed)
        }
        
        let mandate = state.directDebitMandate
        
        let body = DirectDebitCreateMandateRequest(
            id: configId,
            userDetails: UserDetails(
                firstName: mandate.firstName ?? "",
                lastName: mandate.lastName ?? "",
                email: mandate.email ?? "",
                addressLine1: mandate.address?.addressLine1 ?? "",
                addressLine2: mandate.address?.addressLine2 ?? "",
                city: mandate.address?.city ?? "",
                postalCode: mandate.address?.postalCode ?? "",
                countryCode: mandate.address?.countryCode ?? ""
            ),
            bankDetails: BankDetails(
                iban: mandate.iban,
                bankCode: mandate.sortCode,
                accountNumber: mandate.accountNumber
            )
        )
        
        api.directDebitCreateMandate(clientToken: clientToken, mandateRequest: body) { [weak self] result in
            switch result {
            case .failure:
                completion(PrimerError.DirectDebitSessionFailed)
            case .success(let response):
                self?.state.mandateId = response.mandateId
                completion(nil)
            }
        }
    }
}

struct DirectDebitCreateMandateRequest: Codable {
    let id: String
    let userDetails: UserDetails
    let bankDetails: BankDetails
    var path: String = "/gocardless/mandates"
}

struct UserDetails: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let addressLine1: String
    let addressLine2: String
    let city: String
    let postalCode: String
    let countryCode: String
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
