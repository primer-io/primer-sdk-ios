@testable import PrimerSDK
import XCTest

final class MockPrimerAPIConfigurationModule: PrimerAPIConfigurationModuleProtocol {
    static var apiClient: PrimerAPIClientProtocol?

    static var clientToken: JWTToken? {
        return PrimerAPIConfigurationModule.clientToken
    }

    static var decodedJWTToken: DecodedJWTToken? {
        return PrimerAPIConfigurationModule.decodedJWTToken
    }

    static var apiConfiguration: PrimerAPIConfiguration? {
        return PrimerAPIConfigurationModule.apiConfiguration
    }

    static func resetSession() {
        PrimerAPIConfigurationModule.resetSession()
    }

    // MARK: - MOCKED PROPERTIES

    var mockedNetworkDelay: TimeInterval = 0.5
    var mockedAPIConfiguration: PrimerAPIConfiguration?

    func setupSession(
        forClientToken clientToken: String,
        requestDisplayMetadata: Bool,
        requestClientTokenValidation: Bool,
        requestVaultedPaymentMethods: Bool
    ) -> Promise<Void> {
        return Promise { seal in
            guard let mockedAPIConfiguration = mockedAPIConfiguration else {
                XCTAssert(false, "Set 'mockedAPIConfiguration' on your MockPrimerAPIConfigurationModule")
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
                PrimerAPIConfigurationModule.clientToken = clientToken
                PrimerAPIConfigurationModule.apiConfiguration = mockedAPIConfiguration
                seal.fulfill()
            }
        }
    }

    func setupSession(
        forClientToken clientToken: String,
        requestDisplayMetadata: Bool,
        requestClientTokenValidation: Bool,
        requestVaultedPaymentMethods: Bool
    ) async throws {
        guard let mockedAPIConfiguration else {
            XCTAssert(false, "Set 'mockedAPIConfiguration' on your MockPrimerAPIConfigurationModule")
            return
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        PrimerAPIConfigurationModule.clientToken = clientToken
        PrimerAPIConfigurationModule.apiConfiguration = mockedAPIConfiguration
    }

    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) -> Promise<Void> {
        return Promise { _ in
            guard let mockedAPIConfiguration = mockedAPIConfiguration else {
                XCTAssert(false, "Set 'mockedAPIConfiguration' on your MockPrimerAPIConfigurationModule")
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
                PrimerAPIConfigurationModule.apiConfiguration = mockedAPIConfiguration
            }
        }
    }

    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) async throws {
        guard let mockedAPIConfiguration = mockedAPIConfiguration else {
            XCTAssert(false, "Set 'mockedAPIConfiguration' on your MockPrimerAPIConfigurationModule")
            return
        }

        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        PrimerAPIConfigurationModule.apiConfiguration = mockedAPIConfiguration
    }

    func storeRequiredActionClientToken(_ newClientToken: String) -> Promise<Void> {
        return Promise { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.mockedNetworkDelay) {
                PrimerAPIConfigurationModule.clientToken = newClientToken
            }
        }
    }

    func storeRequiredActionClientToken(_ newClientToken: String) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockedNetworkDelay * 1_000_000_000))

        PrimerAPIConfigurationModule.clientToken = newClientToken
    }
}
