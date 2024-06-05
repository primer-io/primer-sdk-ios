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

    struct EmptyCodable: Codable, Equatable {
    }

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

    func testResponseCreation_Empty_Success() throws {
        let model = SuccessResponse()
        let metadata = ResponseMetadataModel(responseUrl: "a_url", statusCode: 200, headers: nil)

        let successResponseFactory = SuccessResponseFactory()
        let responseModel: SuccessResponse = try successResponseFactory.model(for: Data(),
                                                                              forMetadata: metadata)
        XCTAssertEqual(model, responseModel)
    }

    func testResponseCreation_NonJsonToEmpty_Success() throws {
        let model = SuccessResponse()
        let metadata = ResponseMetadataModel(responseUrl: "a_url", statusCode: 200, headers: nil)

        let jsonNetworkResponseFactory = SuccessResponseFactory()
        let string = "<html><head></head><body><a>test</a></body></html>"
        let responseModel: SuccessResponse = try jsonNetworkResponseFactory.model(for: string.data(using: .utf8)!,
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
            XCTAssertTrue(error.errorDescription!.hasPrefix(
                "[failed-to-decode] Failed to decode (Failed to decode response of type \'TestCodable\' from URL: a_url"
            ))
        } catch {
            XCTFail() // should be failed-to-decode only
        }
    }

    func testResponseCreation_errorStatus_Failure() throws {
        let jsonNetworkResponseFactory = JSONNetworkResponseFactory()
        let metadata = ResponseMetadataModel(responseUrl: "a_url", statusCode: 400, headers: nil)
        do {
            let _: EmptyCodable = try jsonNetworkResponseFactory.model(for: Data(), forMetadata: metadata)
            XCTFail()
        } catch let error as InternalError {
            XCTAssertEqual(error.errorId, "server-error")
        } catch {
            XCTFail() // should be failed-to-decode only
        }
    }

    func testResponseCreation_unknownStatus_Failure() throws {
        let jsonNetworkResponseFactory = JSONNetworkResponseFactory()
        let metadata = ResponseMetadataModel(responseUrl: "a_url", statusCode: 0, headers: nil)
        do {
            let _: EmptyCodable = try jsonNetworkResponseFactory.model(for: Data(), forMetadata: metadata)
            XCTFail()
        } catch let error as InternalError {
            XCTAssertEqual(error.errorId, "failed-to-decode")
        } catch {
            XCTFail() // should be failed-to-decode only
        }
    }
}
