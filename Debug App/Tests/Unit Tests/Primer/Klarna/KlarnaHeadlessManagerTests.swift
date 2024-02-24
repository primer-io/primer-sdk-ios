//
//  PrimerHeadlessKlarnaManagerTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 28.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import XCTest
@testable import PrimerSDK

final class PrimerHeadlessUniversalCheckoutKlarnaManagerTests: XCTestCase {
    
    var manager: PrimerHeadlessUniversalCheckout.KlarnaManager!
    var klarnaComponent: (any KlarnaComponent)!
    
    override func setUp() {
        super.setUp()
        prepareConfigurations()
        manager = PrimerHeadlessUniversalCheckout.KlarnaManager()
    }
    
    override func tearDown() {
        restartPrimerConfiguration()
        super.tearDown()
    }
    
    func test_manager_initialization_succeed() {
        XCTAssertNotNil(manager)
    }
    
    func test_klarnaComponent_initialization_succeed() {
        let sessionIntent: PrimerSessionIntent = .checkout
        klarnaComponent = try? manager.provideKlarnaComponent(with: sessionIntent)
        
        XCTAssertNotNil(klarnaComponent)
    }
}

extension PrimerHeadlessUniversalCheckoutKlarnaManagerTests {
    private func setupPrimerConfiguration(paymentMethod: PrimerPaymentMethod, apiConfiguration: PrimerAPIConfiguration) {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchConfigurationWithActionsResult = (apiConfiguration, nil)
        mockApiClient.mockSuccessfulResponses()
        
        AppState.current.clientToken = KlarnaTestsMocks.clientToken
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
    }
    
    private func prepareConfigurations() {
        PrimerInternal.shared.intent = .checkout
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        successApiConfiguration.paymentMethods?[0].baseLogoImage = PrimerTheme.BaseImage(colored: UIImage(), light: nil, dark: nil)
        setupPrimerConfiguration(paymentMethod: Mocks.PaymentMethods.klarnaPaymentMethod, apiConfiguration: successApiConfiguration)
    }
    
    private func restartPrimerConfiguration() {
        manager = nil
        klarnaComponent = nil
        AppState.current.clientToken = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
        PrimerAPIConfigurationModule.apiClient = nil
    }
    
    private func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken(
            userInfo: self.getErrorUserInfo(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
    
    private func getErrorUserInfo() -> [String: String] {
        return [
            "file": #file,
            "class": "\(Self.self)",
            "function": #function,
            "line": "\(#line)"
        ]
    }
}

#endif
