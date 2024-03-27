//
//  NetworkResponseFactoryTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 18/03/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class NetworkResponseFactoryTests: XCTestCase {

    struct TestCodable: Codable, Equatable {
        let value: String
    }

    func testResponseCreation_SimpleJSON_Success() throws {
        let model = TestCodable(value: "TEST_VALUE")
        let data = try JSONEncoder().encode(model)
        let metadata = ResponseMetadataModel(responseUrl: "a_url", statusCode: 200, headers: nil)

        let jsonNetworkResponseFactory = JSONNetworkResponseFactory()
        let responseModel: TestCodable = try jsonNetworkResponseFactory.model(for: data, 
                                                                              forMetadata: metadata)

        XCTAssertEqual(model, responseModel)
    }

    func testResponseCreation_Empty_Failure() throws {
        let jsonNetworkResponseFactory = JSONNetworkResponseFactory()
        let metadata = ResponseMetadataModel(responseUrl: "a_url", statusCode: 200, headers: nil)
        do {
            let _: TestCodable = try jsonNetworkResponseFactory.model(for: Data(), forMetadata: metadata)
            XCTFail()
        } catch let error as InternalError {
            XCTAssertEqual(error.errorId, "failed-to-decode")
        } catch {
            XCTFail() // should be failed-to-decode only
        }
    }
}
