import Foundation
@testable import PrimerSDK

final class MockBINDataAPIClient: PrimerAPIClientBINDataProtocol {

    class AnyCancellable: PrimerCancellable {
        let canceller: () -> Void

        var isCancelled = false

        init(_ canceller: @escaping () -> Void) {
            self.canceller = canceller
        }

        deinit {
            canceller()
        }

        func cancel() {
            canceller()
            isCancelled = true
        }
    }

    var results: [String: Response.Body.Bin.Networks] = [:]

    var error: Error?

    typealias ResponseCompletion = (Result<PrimerSDK.Response.Body.Bin.Networks, Error>) -> Void

    func listCardNetworks(clientToken: PrimerSDK.DecodedJWTToken,
                          bin: String,
                          completion: @escaping ResponseCompletion) -> PrimerSDK.PrimerCancellable? {
        let workItem = DispatchWorkItem { [self] in
            if let error = error {
                completion(.failure(error))
            } else if let result = results[bin] {
                completion(.success(result))
            }
        }

        let cancellable = AnyCancellable {
            workItem.cancel()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)

        return cancellable
    }

    func listCardNetworks(clientToken: PrimerSDK.DecodedJWTToken, bin: String) async throws -> PrimerSDK.Response.Body.Bin.Networks {
        if let error = error {
            throw error
        } else if let result = results[bin] {
            return result
        } else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }
}
