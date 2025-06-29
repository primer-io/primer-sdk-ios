import AuthenticationServices
@testable import PrimerSDK

class MockWebAuthenticationService: WebAuthenticationService {
    var session: ASWebAuthenticationSession?
    var onConnect: ((URL, String) -> URL)?

    func connect(paymentMethodType: String, url: URL, scheme: String, _ completion: @escaping (Result<URL, any Error>) -> Void) {
        guard let onConnect = onConnect else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
            return
        }

        completion(.success(onConnect(url, scheme)))
    }

    func connect(paymentMethodType: String, url: URL, scheme: String) async throws -> URL {
        guard let onConnect = onConnect else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
        return onConnect(url, scheme)
    }
}
