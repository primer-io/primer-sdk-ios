//
//  DirectDebitService.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 22/01/2021.
//

#if canImport(UIKit)

internal protocol DirectDebitServiceProtocol {
    func createMandate(_ completion: @escaping (Error?) -> Void)
}

internal class DirectDebitService: DirectDebitServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func createMandate(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = ClientTokenService.decodedClientToken else {
            return completion(PrimerError.directDebitSessionFailed)
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .goCardlessMandate) else {
            return completion(PrimerError.directDebitSessionFailed)
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        guard let customer = settings.customer else {
            return completion(PrimerError.userDetailsMissing)
        }

        let mandate = state.directDebitMandate
        
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
                completion(PrimerError.directDebitSessionFailed)
            case .success(let response):
                state.mandateId = response.mandateId
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

public struct Customer: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let homePhoneNumber: String?
    let mobilePhoneNumber: String?
    let workPhoneNumber: String?
    let billingAddress: Address?
    
    public init(
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        homePhoneNumber: String? = nil,
        mobilePhoneNumber: String? = nil,
        workPhoneNumber: String? = nil,
        billingAddress: Address? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.homePhoneNumber = homePhoneNumber
        self.mobilePhoneNumber = mobilePhoneNumber
        self.workPhoneNumber = workPhoneNumber
        self.billingAddress = billingAddress
    }
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
