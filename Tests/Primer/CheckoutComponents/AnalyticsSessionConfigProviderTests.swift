//
//  AnalyticsSessionConfigProviderTests.swift
//  PrimerSDKTests
//

@testable import PrimerSDK
import Foundation
import XCTest

final class AnalyticsSessionConfigProviderTests: XCTestCase {

    private let tokenWithIds = AnalyticsTestTokens.withIds
    private let tokenWithoutIds = AnalyticsTestTokens.withoutIds

    override func tearDown() {
        super.tearDown()
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
    }

    func test_makeAnalyticsSessionConfig_fallsBackToClientTokenPayload() {
        // Given
        let module = PrimerAPIConfigurationModule()
        PrimerAPIConfigurationModule.clientToken = tokenWithIds
        PrimerAPIConfigurationModule.apiConfiguration = nil

        // When
        let result = module.makeAnalyticsSessionConfig(
            checkoutSessionId: "checkout-session",
            clientToken: tokenWithIds,
            sdkVersion: "0.0.1"
        )

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.clientSessionId, "token-session-id")
        XCTAssertEqual(result?.primerAccountId, "token-account-id")
        XCTAssertEqual(result?.environment, .sandbox)
    }

    func test_makeAnalyticsSessionConfig_returnsNilWhenIdentifiersMissing() {
        // Given
        let module = PrimerAPIConfigurationModule()
        PrimerAPIConfigurationModule.clientToken = tokenWithoutIds
        PrimerAPIConfigurationModule.apiConfiguration = nil

        // When
        let result = module.makeAnalyticsSessionConfig(
            checkoutSessionId: "checkout-session",
            clientToken: tokenWithoutIds,
            sdkVersion: "0.0.1"
        )

        // Then
        XCTAssertNil(result)
    }
}

@available(iOS 15.0, *)
@MainActor
final class CheckoutSDKInitializerAnalyticsProviderTests: XCTestCase {

    private let tokenWithIds = AnalyticsTestTokens.withIds

    override func tearDown() {
        super.tearDown()
        PrimerInternal.shared.checkoutSessionId = nil
        PrimerInternal.shared.sdkIntegrationType = nil
        PrimerInternal.shared.intent = nil
    }

    func test_initialize_invokesAnalyticsConfigProvider() async throws {
        // Given
        let configurationModule = StubConfigurationModule()
        let initializer = CheckoutSDKInitializer(
            clientToken: tokenWithIds,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator(),
            presentationContext: .fromPaymentSelection,
            configurationModule: configurationModule
        )

        // When
        _ = try await initializer.initialize()

        // Then
        XCTAssertEqual(configurationModule.setupSessionCallCount, 1)
        XCTAssertEqual(configurationModule.capturedConfigParameters?.clientToken, tokenWithIds)
        XCTAssertEqual(configurationModule.capturedConfigParameters?.checkoutSessionId, PrimerInternal.shared.checkoutSessionId)
        XCTAssertFalse(configurationModule.capturedConfigParameters?.sdkVersion.isEmpty ?? true)
    }
}

private final class StubConfigurationModule: PrimerAPIConfigurationModuleProtocol, AnalyticsSessionConfigProviding {

    static var apiClient: PrimerAPIClientProtocol?
    static var clientToken: JWTToken?
    static var decodedJWTToken: DecodedJWTToken?
    static var apiConfiguration: PrimerAPIConfiguration?

    static func resetSession() {}

    var setupSessionCallCount = 0
    var capturedConfigParameters: (checkoutSessionId: String, clientToken: String, sdkVersion: String)?

    func setupSession(
        forClientToken clientToken: String,
        requestDisplayMetadata: Bool,
        requestClientTokenValidation: Bool,
        requestVaultedPaymentMethods: Bool
    ) async throws {
        setupSessionCallCount += 1
    }

    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) async throws {}

    func storeRequiredActionClientToken(_ newClientToken: String) async throws {}

    func makeAnalyticsSessionConfig(
        checkoutSessionId: String,
        clientToken: String,
        sdkVersion: String
    ) -> AnalyticsSessionConfig? {
        capturedConfigParameters = (checkoutSessionId, clientToken, sdkVersion)
        return nil
    }
}

private enum AnalyticsTestTokens {

    static let withIds = JWTTestTokenFactory.makeJWT(payload: [
        "env": "SANDBOX",
        "clientSessionId": "token-session-id",
        "primerAccountId": "token-account-id"
    ])

    static let withoutIds = JWTTestTokenFactory.makeJWT(payload: [
        "env": "PRODUCTION"
    ])
}

private enum JWTTestTokenFactory {

    static func makeJWT(
        header: [String: Any] = ["alg": "HS256", "typ": "JWT"],
        payload: [String: Any]
    ) -> String {
        let headerSegment = encode(json: header)
        let payloadSegment = encode(json: payload)
        let signatureSegment = base64URLEncode(Data("signature".utf8))
        return [headerSegment, payloadSegment, signatureSegment].joined(separator: ".")
    }

    private static func encode(json: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(json),
              let data = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]) else {
            preconditionFailure("Failed to serialize JWT segment for tests.")
        }
        return base64URLEncode(data)
    }

    private static func base64URLEncode(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
