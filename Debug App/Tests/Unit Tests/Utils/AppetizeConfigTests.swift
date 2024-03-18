//
//  AppetizeConfigTests.swift
//  Debug App Tests
//
//  Created by Niall Quinn on 12/03/24.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import Debug_App

final class AppetizeConfigTests: XCTestCase {

    func test_fetchConfig() throws {
        let mockConfig = SessionConfiguration.mockConfig

        let mockPayloadProvider = MockPayloadProvider(config: mockConfig)

        let configProvider = AppetizeConfigProvider(payloadProvider: mockPayloadProvider)

        let fetchedConfig = configProvider.fetchConfig()

        XCTAssertEqual(fetchedConfig, mockConfig)
    }

    func test_fetchNoConfig() throws {

        let mockPayloadProvider = MockPayloadProvider(config: nil)

        let configProvider = AppetizeConfigProvider(payloadProvider: mockPayloadProvider)

        let fetchedConfig = configProvider.fetchConfig()

        XCTAssertNil(fetchedConfig)
    }
}

private struct MockPayloadProvider: AppetizePayloadProviding {
    var isAppetize: Bool?
    var configJwt: String?

    init(config: SessionConfiguration?) {
        guard let config else {
            self.isAppetize = false
            self.configJwt = nil
            return
        }
        self.isAppetize = true
        self.configJwt = config.base64Encoded
    }
}

private extension SessionConfiguration {
    var base64Encoded: String? {
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(self) {
            let base64String = jsonData.base64EncodedString()
            return base64String
        } else {
            return nil
        }
    }

    static var mockConfig: SessionConfiguration {
        .init(customerId: "mock-customerId",
              locale: "mock-locale",
              paymentFlow: "mock-paymentFlow",
              currency: "mock-currency",
              countryCode: "mock-countryCode",
              value: "mock-value",
              surchargeEnabled: false,
              applePaySurcharge: 0,
              firstName: "mock-firstName",
              lastName: "mock-lastName",
              email: "mock-email",
              mobileNumber: "mock-mobileNumber",
              addressLine1: "mock-addressLine1",
              state: "mock-state",
              city: "mock-city",
              postalCode: "mock-postalCode",
              vault: false,
              newWorkflows: false,
              environment: "mock-environment",
              customApiKey: "mock-customApiKey",
              metadata: "mock-metadata")
    }
}
