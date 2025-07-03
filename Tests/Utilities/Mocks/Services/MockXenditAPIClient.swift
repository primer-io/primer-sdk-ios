@testable import PrimerSDK

final class MockXenditAPIClient: PrimerAPIClientXenditProtocol {

    var onListRetailOutlets: ((DecodedJWTToken, String) -> RetailOutletsList)?

    func listRetailOutlets(clientToken: DecodedJWTToken, paymentMethodId: String, completion: @escaping PrimerSDK.APICompletion<PrimerSDK.RetailOutletsList>) {
        if let onListRetailOutlets = onListRetailOutlets {
            completion(.success(onListRetailOutlets(clientToken, paymentMethodId)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    func listRetailOutlets(clientToken: DecodedJWTToken, paymentMethodId: String) async throws -> RetailOutletsList {
        if let onListRetailOutlets = onListRetailOutlets {
            return onListRetailOutlets(clientToken, paymentMethodId)
        } else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }
}
