//
//  NetworkRequestFactoryTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 18/03/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class NetworkRequestFactoryTests: XCTestCase {

    var networkRequestFactory: NetworkRequestFactory!

    func defaultHeaders(apiVersion: String = "2.2",
                        isPost: Bool = false,
                        jwt: String? = nil) -> [String: String] {
        var headers = [
            "X-Api-Version": apiVersion,
            "Primer-SDK-Version": VersionUtils.releaseVersionNumber ?? "n/a",
            "Primer-SDK-Client": "IOS_NATIVE"
        ]
        if isPost {
            headers["Content-Type"] = "application/json"
        }
        if let jwt = jwt {
            headers["Primer-Client-Token"] = jwt
        }
        return headers
    }

    override func setUpWithError() throws {
        SDKSessionHelper.setUp()
        PrimerInternal.shared.checkoutSessionId = nil
        networkRequestFactory = DefaultNetworkRequestFactory()
    }

    override func tearDownWithError() throws {
        networkRequestFactory = nil
        SDKSessionHelper.tearDown()
    }

    func testRequestCreation_createPayment() throws {

        let body = Request.Body.Payment.Create(token: "MY_TOKEN")
        let endpoint = PrimerAPI.createPayment(clientToken: Mocks.decodedJWTToken, paymentRequest: body)
        let request = try networkRequestFactory.request(for: endpoint)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "pci_url/payments")
        XCTAssertEqual(request.httpBody, body.asJSONData)
        XCTAssertEqual(request.allHTTPHeaderFields, defaultHeaders(isPost: true, jwt: "bla"))
    }

    func testRequestCreation_configuration() throws {
        let body = Request.URLParameters.Configuration(skipPaymentMethodTypes: nil, requestDisplayMetadata: true)
        let endpoint = PrimerAPI.fetchConfiguration(clientToken: Mocks.decodedJWTToken, requestParameters: body)
        let request = try networkRequestFactory.request(for: endpoint)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.absoluteString, Mocks.decodedJWTToken.configurationUrl)
        XCTAssertEqual(request.allHTTPHeaderFields, defaultHeaders(jwt: "bla"))
    }

    func testRequestCreation_paymentInstruments() throws {
        let endpoint = PrimerAPI.fetchVaultedPaymentMethods(clientToken: Mocks.decodedJWTToken)
        let request = try networkRequestFactory.request(for: endpoint)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.absoluteString, "pci_url/payment-instruments")
        XCTAssertEqual(request.allHTTPHeaderFields, defaultHeaders(jwt: "bla"))
    }

    func testRequestCreation_listCardNetworks() throws {
        let endpoint = PrimerAPI.listCardNetworks(clientToken: Mocks.decodedJWTToken, bin: "1234")
        let request = try networkRequestFactory.request(for: endpoint)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.absoluteString, "bindata_url/v1/bin-data/1234/networks")
        XCTAssertEqual(request.allHTTPHeaderFields, defaultHeaders(jwt: "bla"))
    }

}
