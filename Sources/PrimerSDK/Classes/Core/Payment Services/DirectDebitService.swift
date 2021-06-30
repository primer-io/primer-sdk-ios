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
        
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.directDebitSessionFailed)
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .goCardlessMandate) else {
            return completion(PrimerError.directDebitSessionFailed)
        }

        let mandate = state.directDebitMandate
        
        let userDetails = UserDetails(
            firstName: mandate.firstName ?? "",
            lastName: mandate.lastName ?? "",
            email: mandate.email ?? "",
            addressLine1: mandate.address?.addressLine1 ?? "",
            addressLine2: mandate.address?.addressLine2 ?? "",
            city: mandate.address?.city ?? "",
            postalCode: mandate.address?.postalCode ?? "",
            countryCode: mandate.address?.countryCode ?? "",
            homePhone: nil,
            mobilePhone: nil,
            workPhone: nil)
        
        let bankDetails = BankDetails(
            iban: mandate.iban,
            bankCode: mandate.sortCode,
            accountNumber: mandate.accountNumber)

        let body = DirectDebitCreateMandateRequest(
            id: configId,
            userDetails: userDetails,
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
    let userDetails: UserDetails
    let bankDetails: BankDetails
}

public struct UserDetails: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let addressLine1: String
    let addressLine2: String
    let city: String
    let postalCode: String
    let countryCode: String
    let homePhone: String?
    let mobilePhone: String?
    let workPhone: String?
    
    public init(
        firstName: String,
        lastName: String,
        email: String,
        addressLine1: String,
        addressLine2: String,
        city: String,
        postalCode: String,
        countryCode: String,
        homePhone: String?,
        mobilePhone: String?,
        workPhone: String?
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.city = city
        self.postalCode = postalCode
        self.countryCode = countryCode
        self.homePhone = homePhone
        self.mobilePhone = mobilePhone
        self.workPhone = workPhone
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
