import Foundation
@testable import PrimerSDK

internal extension Timer {

    static func delay(_ timeInterval: TimeInterval) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
                seal.fulfill()
            }
        }
    }
    
    static func delay(_ timeInterval: TimeInterval) async throws {
        if #available(iOS 16.0, *) {
            try await Task.sleep(for: .seconds(timeInterval))
        } else {
            try await Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
        }
    }
}
