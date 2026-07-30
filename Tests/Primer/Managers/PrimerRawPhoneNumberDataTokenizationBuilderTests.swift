//
//  PrimerRawPhoneNumberDataTokenizationBuilderTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerNetworking

/// Holds a mocked lookup open until the test releases it, so response ordering is controlled
/// explicitly rather than by sleeping.
private final class Gate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false

    func wait() async {
        // open() can land first — without this the continuation is never installed and we hang.
        guard !isOpen else { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}

final class PrimerRawPhoneNumberDataTokenizationBuilderTests: XCTestCase {

    private static let paymentMethodType = "XENDIT_OVO"
    private static let validResponse = Response.Body.PhoneMetadata.PhoneMetadataDataResponse(
        isValid: true,
        countryCode: "62",
        nationalNumber: "81234567890"
    )
    private static let invalidResponse = Response.Body.PhoneMetadata.PhoneMetadataDataResponse(
        isValid: false,
        countryCode: nil,
        nationalNumber: nil
    )
    private static let validNumber = "+6281234567890"
    private static let ovoPaymentMethod = PrimerPaymentMethod(
        id: "payment_method_id",
        implementationType: .nativeSdk,
        type: paymentMethodType,
        name: "Xendit OVO",
        processorConfigId: nil,
        surcharge: nil,
        options: nil,
        displayMetadata: nil
    )

    private var mockApiClient: MockPrimerAPIClient!

    override func setUp() {
        super.setUp()
        SDKSessionHelper.setUp(withPaymentMethods: [Self.ovoPaymentMethod])
        mockApiClient = MockPrimerAPIClient()
        mockApiClient.mockedNetworkDelay = 0
        mockApiClient.getPhoneMetadataResult = .success(Self.validResponse)
    }

    override func tearDown() {
        mockApiClient = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - requiredInputElementTypes

    func test_requiredInputElementTypes_shouldReturnPhoneNumberType() {
        XCTAssertEqual(makeBuilder().requiredInputElementTypes, [.phoneNumber])
    }

    // MARK: - validateRawData

    func test_validateRawData_withInvalidDataType_shouldFail() async {
        let builder = makeBuilder()
        let invalidRawData = PrimerOTPData(otp: "123456")

        do {
            try await builder.validateRawData(invalidRawData)
            XCTFail("Expected validation to fail with a non-phone raw data type")
        } catch {
            XCTAssert(error is PrimerValidationError)
        }
        XCTAssertFalse(builder.isDataValid)
    }

    func test_validateRawData_withBlankNumber_shouldFailWithoutCallingLookup() async {
        let builder = makeBuilder()

        do {
            try await builder.validateRawData(PrimerPhoneNumberData(phoneNumber: "   "))
            XCTFail("Expected validation to fail for a blank phone number")
        } catch {
            // Expected
        }
        XCTAssertFalse(builder.isDataValid)
        XCTAssertEqual(mockApiClient.getPhoneMetadataCallCount, 0)
    }

    func test_validateRawData_shouldLookUpTheNumberAsTyped() async throws {

        try await makeBuilder().validateRawData(PrimerPhoneNumberData(phoneNumber: "+6281234567890"))

        XCTAssertEqual(mockApiClient.getPhoneMetadataRequestedNumbers, ["+6281234567890"])
    }

    func test_validateRawData_whenLookupSaysValid_shouldSucceed() async throws {
        let builder = makeBuilder()

        try await builder.validateRawData(PrimerPhoneNumberData(phoneNumber: "+6281234567890"))

        XCTAssertTrue(builder.isDataValid)
    }

    func test_validateRawData_whenLookupSaysInvalid_shouldFail() async {
        mockApiClient.getPhoneMetadataResult = .success(Self.invalidResponse)
        let builder = makeBuilder()

        do {
            try await builder.validateRawData(PrimerPhoneNumberData(phoneNumber: "+6281"))
            XCTFail("Expected validation to fail when the lookup reports the number invalid")
        } catch {
            // Expected
        }
        XCTAssertFalse(builder.isDataValid)
    }

    func test_validateRawData_whenLookupIsValidButPartsMissing_shouldFail() async {
        mockApiClient.getPhoneMetadataResult = .success(.init(isValid: true, countryCode: nil, nationalNumber: nil))
        let builder = makeBuilder()

        do {
            try await builder.validateRawData(PrimerPhoneNumberData(phoneNumber: "+6281234567890"))
            XCTFail("Expected validation to fail when the lookup returns no parsed number")
        } catch {
            // Expected
        }
        XCTAssertFalse(builder.isDataValid)
    }

    func test_validateRawData_whenLookupFails_shouldThrow() async {
        mockApiClient.getPhoneMetadataResult = .failure(PrimerError.unknown(message: "network down"))
        let builder = makeBuilder()

        do {
            try await builder.validateRawData(PrimerPhoneNumberData(phoneNumber: "+6281234567890"))
            XCTFail("Expected the lookup failure to propagate")
        } catch {
            XCTAssert(error is PrimerError)
        }
    }

    // MARK: - makeRequestBodyWithRawData

    // Android submits the shopper's own string, so iOS must too — the lookup is only a yes/no.
    func test_makeRequestBody_shouldSubmitTheApprovedInputVerbatim() async throws {
        let builder = makeBuilder()
        let typed = "+62 812 3456 7890"
        let rawData = PrimerPhoneNumberData(phoneNumber: typed)

        try await builder.validateRawData(rawData)
        let requestBody = try await builder.makeRequestBodyWithRawData(rawData)

        XCTAssertEqual(submittedPhoneNumber(in: requestBody), typed)
    }

    func test_makeRequestBody_withoutPriorValidation_shouldThrow() async {
        let builder = makeBuilder()

        do {
            _ = try await builder.makeRequestBodyWithRawData(PrimerPhoneNumberData(phoneNumber: "+6281234567890"))
            XCTFail("Expected failure when no verified number is held")
        } catch {
            XCTAssert(error is PrimerError)
        }
    }

    func test_makeRequestBody_whenInputChangedAfterValidation_shouldThrow() async throws {
        let builder = makeBuilder()
        try await builder.validateRawData(PrimerPhoneNumberData(phoneNumber: "+6281234567890"))

        do {
            _ = try await builder.makeRequestBodyWithRawData(PrimerPhoneNumberData(phoneNumber: "+6289999999999"))
            XCTFail("Expected failure when the verified number belongs to different input")
        } catch {
            guard case let PrimerError.invalidValue(key, _, _, _) = error else {
                return XCTFail("Expected invalidValue, got \(error)")
            }
            XCTAssertEqual(key, "phoneNumber")
        }
    }

    // The older lookup answers last; its verdict must not win.
    func test_supersededLookupFailure_shouldNotOverwriteNewerSuccess() async throws {
        let partial = "+6281"
        let staleGate = Gate()
        let staleStarted = expectation(description: "superseded lookup reached the network")
        mockApiClient.getPhoneMetadataHandler = { number in
            guard number == partial else {
                return Self.validResponse
            }
            staleStarted.fulfill()
            await staleGate.wait()
            return Self.invalidResponse
        }
        let builder = makeBuilder()
        let completeData = PrimerPhoneNumberData(phoneNumber: Self.validNumber)

        let stale = Task { try? await builder.validateRawData(PrimerPhoneNumberData(phoneNumber: partial)) }
        await fulfillment(of: [staleStarted], timeout: 2)

        try await builder.validateRawData(completeData)
        XCTAssertTrue(builder.isDataValid)

        staleGate.open()
        _ = await stale.value

        XCTAssertTrue(builder.isDataValid, "A superseded lookup must not flip validity")
        let requestBody = try await builder.makeRequestBodyWithRawData(completeData)
        XCTAssertEqual(submittedPhoneNumber(in: requestBody), Self.validNumber)
    }

    func test_lookupFailureAfterSuccess_shouldDiscardVerifiedNumber() async throws {
        let builder = makeBuilder()
        let rawData = PrimerPhoneNumberData(phoneNumber: Self.validNumber)
        try await builder.validateRawData(rawData)
        XCTAssertTrue(builder.isDataValid)

        mockApiClient.getPhoneMetadataResult = .failure(PrimerError.unknown(message: "network down"))
        try? await builder.validateRawData(rawData)

        XCTAssertFalse(builder.isDataValid)
        do {
            _ = try await builder.makeRequestBodyWithRawData(rawData)
            XCTFail("Expected failure after the verified number was discarded")
        } catch {
            XCTAssert(error is PrimerError)
        }
    }

    func test_makeRequestBody_withInvalidDataType_shouldFail() async {
        let builder = makeBuilder()

        do {
            _ = try await builder.makeRequestBodyWithRawData(PrimerOTPData(otp: "123456"))
            XCTFail("Expected failure when raw data is not a phone number")
        } catch {
            XCTAssert(error is PrimerError)
        }
    }

    func test_makeRequestBody_withUnknownPaymentMethodType_shouldFail() async {
        let builder = PrimerRawPhoneNumberDataTokenizationBuilder(
            paymentMethodType: "NOT_A_PAYMENT_METHOD",
            apiClient: mockApiClient
        )

        do {
            _ = try await builder.makeRequestBodyWithRawData(PrimerPhoneNumberData(phoneNumber: "+6281234567890"))
            XCTFail("Expected failure for an unknown payment method type")
        } catch {
            XCTAssert(error is PrimerError)
        }
    }

    // MARK: - Helpers

    private func makeBuilder() -> PrimerRawPhoneNumberDataTokenizationBuilder {
        PrimerRawPhoneNumberDataTokenizationBuilder(
            paymentMethodType: Self.paymentMethodType,
            apiClient: mockApiClient
        )
    }

    private func submittedPhoneNumber(in requestBody: Request.Body.Tokenization) -> String? {
        guard let instrument = requestBody.paymentInstrument as? OffSessionPaymentInstrument,
              let sessionInfo = instrument.sessionInfo as? InputPhonenumberSessionInfo else {
            XCTFail("Expected an OffSessionPaymentInstrument carrying InputPhonenumberSessionInfo")
            return nil
        }
        return sessionInfo.phoneNumber
    }

}
