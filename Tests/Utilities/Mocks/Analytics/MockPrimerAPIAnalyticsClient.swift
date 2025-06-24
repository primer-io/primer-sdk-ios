import XCTest
@testable import PrimerSDK

class MockPrimerAPIAnalyticsClient: PrimerAPIClientAnalyticsProtocol {

    var shouldSucceed: Bool = true

    var onSendAnalyticsEvent: (([PrimerSDK.Analytics.Event]?) -> Void)?

    var batches: [[Analytics.Event]] = []

    func sendAnalyticsEvents(clientToken: DecodedJWTToken?, url: URL, body: [Analytics.Event]?, completion: @escaping ResponseHandler) {
        guard let body = body else {
            XCTFail(); return
        }
        batches.append(body)
        if shouldSucceed {
            completion(.success(.init(id: nil, result: nil)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
        self.onSendAnalyticsEvent?(body)
    }

    func sendAnalyticsEvents(clientToken: PrimerSDK.DecodedJWTToken?, url: URL, body: [PrimerSDK.Analytics.Event]?) async throws -> Analytics.Service.Response {
        guard let body = body else {
            XCTFail(); throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
        batches.append(body)
        if shouldSucceed {
            return .init(id: nil, result: nil)
        } else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }
}
