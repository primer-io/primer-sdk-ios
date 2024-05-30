//
//  ThreeDSErrorTests.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 16/5/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(Primer3DS)
import XCTest
@testable import PrimerSDK
import Primer3DS

class ThreeDSErrorTests: XCTestCase {

    func test_3DS_protocol_version_init() throws {
        let initProtocolVersion = "2.1.0"
        let cardNetwork = "CARD-NETWORK"
        let diagnosticsId = "diagnostics-id"

        var primer3DSError = Primer3DSError.missingDsRid(cardNetwork: cardNetwork)
        var primer3DSContainerError = self.createPrimer3DSContainerError(from: primer3DSError,
                                                                         diagnosticsId: diagnosticsId,
                                                                         initProtocolVersion: initProtocolVersion)
        XCTAssert(primer3DSContainerError.initProtocolVersion == initProtocolVersion, "Protocol version should be \(initProtocolVersion)")
        var errorDescription = "[\(primer3DSError.errorId)] \(primer3DSError.errorDescription) (diagnosticsId: \(diagnosticsId))"
        XCTAssert(primer3DSContainerError.errorDescription == errorDescription, "Error description should be '\(errorDescription)'")
        XCTAssert(primer3DSContainerError.diagnosticsId == diagnosticsId, "Error diagnosticsId should be '\(diagnosticsId)'")
        XCTAssert(primer3DSContainerError.recoverySuggestion == primer3DSError.recoverySuggestion, "Error recoverySuggestion should be '\(String(describing: primer3DSError.recoverySuggestion))'")
        XCTAssert(primer3DSContainerError.threeDsErrorCode == primer3DSError.threeDsErrorCode, "3DS error code should be \(String(describing: primer3DSError.threeDsErrorCode))")
        XCTAssert(primer3DSContainerError.threeDsErrorType == primer3DSError.threeDsErrorType, "3DS error type should be \(String(describing: primer3DSError.threeDsErrorType))")
        XCTAssert(primer3DSContainerError.threeDsErrorComponent == primer3DSError.threeDsErrorComponent, "3DS error component should be \(String(describing: primer3DSError.threeDsErrorComponent))")
        XCTAssert(primer3DSContainerError.threeDsErrorDetail == primer3DSError.threeDsErrorDetail, "3DS error detail should be \(String(describing: primer3DSError.threeDsErrorDetail))")
        XCTAssert(primer3DSContainerError.threeDsSErrorVersion == primer3DSError.threeDsSErrorVersion, "3DS error version should be \(String(describing: primer3DSError.threeDsSErrorVersion))")
        XCTAssert(primer3DSContainerError.threeDsSdkTranscationId == primer3DSError.threeDsSdkTranscationId, "3DS error transaction id should be \(String(describing: primer3DSError.threeDsSdkTranscationId))")

        primer3DSError = Primer3DSError.protocolError(
            description: "A protocol error occured",
            code: "666",
            type: "protocol-error-type",
            component: "C",
            transactionId: "transaction-id",
            protocolVersion: "9.9.9",
            details: "details")
        primer3DSContainerError = self.createPrimer3DSContainerError(from: primer3DSError,
                                                                     diagnosticsId: diagnosticsId,
                                                                     initProtocolVersion: initProtocolVersion)
        XCTAssert(primer3DSContainerError.initProtocolVersion == initProtocolVersion, "Protocol version should be \(initProtocolVersion)")
        errorDescription = "[\(primer3DSError.errorId)] \(primer3DSError.errorDescription) (diagnosticsId: \(diagnosticsId))"
        XCTAssert(primer3DSContainerError.errorDescription == errorDescription, "Error description should be '\(errorDescription)'")
        XCTAssert(primer3DSContainerError.diagnosticsId == diagnosticsId, "Error diagnosticsId should be '\(diagnosticsId)'")
        XCTAssert(primer3DSContainerError.recoverySuggestion == primer3DSError.recoverySuggestion, "Error recoverySuggestion should be '\(String(describing: primer3DSError.recoverySuggestion))'")
        XCTAssert(primer3DSContainerError.threeDsErrorCode == primer3DSError.threeDsErrorCode, "3DS error code should be \(String(describing: primer3DSError.threeDsErrorCode))")
        XCTAssert(primer3DSContainerError.threeDsErrorType == primer3DSError.threeDsErrorType, "3DS error type should be \(String(describing: primer3DSError.threeDsErrorType))")
        XCTAssert(primer3DSContainerError.threeDsErrorComponent == primer3DSError.threeDsErrorComponent, "3DS error component should be \(String(describing: primer3DSError.threeDsErrorComponent))")
        XCTAssert(primer3DSContainerError.threeDsErrorDetail == primer3DSError.threeDsErrorDetail, "3DS error detail should be \(String(describing: primer3DSError.threeDsErrorDetail))")
        XCTAssert(primer3DSContainerError.threeDsSErrorVersion == primer3DSError.threeDsSErrorVersion, "3DS error version should be \(String(describing: primer3DSError.threeDsSErrorVersion))")
        XCTAssert(primer3DSContainerError.threeDsSdkTranscationId == primer3DSError.threeDsSdkTranscationId, "3DS error transaction id should be \(String(describing: primer3DSError.threeDsSdkTranscationId))")

        primer3DSError = Primer3DSError.cancelled
        primer3DSContainerError = self.createPrimer3DSContainerError(from: primer3DSError,
                                                                     diagnosticsId: diagnosticsId,
                                                                     initProtocolVersion: initProtocolVersion)
        XCTAssert(primer3DSContainerError.initProtocolVersion == initProtocolVersion, "Protocol version should be \(initProtocolVersion)")
        errorDescription = "[\(primer3DSError.errorId)] \(primer3DSError.errorDescription) (diagnosticsId: \(diagnosticsId))"
        XCTAssert(primer3DSContainerError.errorDescription == errorDescription, "Error description should be '\(errorDescription)'")
        XCTAssert(primer3DSContainerError.diagnosticsId == diagnosticsId, "Error diagnosticsId should be '\(diagnosticsId)'")
        XCTAssert(primer3DSContainerError.recoverySuggestion == primer3DSError.recoverySuggestion, "Error recoverySuggestion should be '\(String(describing: primer3DSError.recoverySuggestion))'")
        XCTAssert(primer3DSContainerError.threeDsErrorCode == primer3DSError.threeDsErrorCode, "3DS error code should be \(String(describing: primer3DSError.threeDsErrorCode))")
        XCTAssert(primer3DSContainerError.threeDsErrorType == primer3DSError.threeDsErrorType, "3DS error type should be \(String(describing: primer3DSError.threeDsErrorType))")
        XCTAssert(primer3DSContainerError.threeDsErrorComponent == primer3DSError.threeDsErrorComponent, "3DS error component should be \(String(describing: primer3DSError.threeDsErrorComponent))")
        XCTAssert(primer3DSContainerError.threeDsErrorDetail == primer3DSError.threeDsErrorDetail, "3DS error detail should be \(String(describing: primer3DSError.threeDsErrorDetail))")
        XCTAssert(primer3DSContainerError.threeDsSErrorVersion == primer3DSError.threeDsSErrorVersion, "3DS error version should be \(String(describing: primer3DSError.threeDsSErrorVersion))")
        XCTAssert(primer3DSContainerError.threeDsSdkTranscationId == primer3DSError.threeDsSdkTranscationId, "3DS error transaction id should be \(String(describing: primer3DSError.threeDsSdkTranscationId))")

        primer3DSError = Primer3DSError.runtimeError(description: "A runtime error occured", code: "666")
        primer3DSContainerError = self.createPrimer3DSContainerError(from: primer3DSError,
                                                                     diagnosticsId: diagnosticsId,
                                                                     initProtocolVersion: initProtocolVersion)
        XCTAssert(primer3DSContainerError.initProtocolVersion == initProtocolVersion, "Protocol version should be \(initProtocolVersion)")
        errorDescription = "[\(primer3DSError.errorId)] \(primer3DSError.errorDescription) (diagnosticsId: \(diagnosticsId))"
        XCTAssert(primer3DSContainerError.errorDescription == errorDescription, "Error description should be '\(errorDescription)'")
        XCTAssert(primer3DSContainerError.diagnosticsId == diagnosticsId, "Error diagnosticsId should be '\(diagnosticsId)'")
        XCTAssert(primer3DSContainerError.recoverySuggestion == primer3DSError.recoverySuggestion, "Error recoverySuggestion should be '\(String(describing: primer3DSError.recoverySuggestion))'")
        XCTAssert(primer3DSContainerError.threeDsErrorCode == primer3DSError.threeDsErrorCode, "3DS error code should be \(String(describing: primer3DSError.threeDsErrorCode))")
        XCTAssert(primer3DSContainerError.threeDsErrorType == primer3DSError.threeDsErrorType, "3DS error type should be \(String(describing: primer3DSError.threeDsErrorType))")
        XCTAssert(primer3DSContainerError.threeDsErrorComponent == primer3DSError.threeDsErrorComponent, "3DS error component should be \(String(describing: primer3DSError.threeDsErrorComponent))")
        XCTAssert(primer3DSContainerError.threeDsErrorDetail == primer3DSError.threeDsErrorDetail, "3DS error detail should be \(String(describing: primer3DSError.threeDsErrorDetail))")
        XCTAssert(primer3DSContainerError.threeDsSErrorVersion == primer3DSError.threeDsSErrorVersion, "3DS error version should be \(String(describing: primer3DSError.threeDsSErrorVersion))")
        XCTAssert(primer3DSContainerError.threeDsSdkTranscationId == primer3DSError.threeDsSdkTranscationId, "3DS error transaction id should be \(String(describing: primer3DSError.threeDsSdkTranscationId))")

        let nsErr = NSError(domain: "3ds-provider", code: 666, userInfo: [NSLocalizedDescriptionKey: "An error was thrown from the 3DS provider SDK"])

        primer3DSError = Primer3DSError.challengeFailed(error: nsErr)
        primer3DSContainerError = self.createPrimer3DSContainerError(from: primer3DSError,
                                                                     paymentMethodType: "TEST_PAYMENT_METHOD",
                                                                     diagnosticsId: diagnosticsId,
                                                                     initProtocolVersion: initProtocolVersion)
        XCTAssert(primer3DSContainerError.initProtocolVersion == initProtocolVersion, "Protocol version should be \(initProtocolVersion)")
        errorDescription = "[\(primer3DSError.errorId)] \(primer3DSError.errorDescription) (diagnosticsId: \(diagnosticsId))"
        XCTAssert(primer3DSContainerError.errorDescription == errorDescription, "Error description should be '\(errorDescription)'")
        XCTAssert(primer3DSContainerError.diagnosticsId == diagnosticsId, "Error diagnosticsId should be '\(diagnosticsId)'")
        XCTAssert(primer3DSContainerError.recoverySuggestion == primer3DSError.recoverySuggestion, "Error recoverySuggestion should be '\(String(describing: primer3DSError.recoverySuggestion))'")
        XCTAssert(primer3DSContainerError.threeDsErrorCode == primer3DSError.threeDsErrorCode, "3DS error code should be \(String(describing: primer3DSError.threeDsErrorCode))")
        XCTAssert(primer3DSContainerError.threeDsErrorType == primer3DSError.threeDsErrorType, "3DS error type should be \(String(describing: primer3DSError.threeDsErrorType))")
        XCTAssert(primer3DSContainerError.threeDsErrorComponent == primer3DSError.threeDsErrorComponent, "3DS error component should be \(String(describing: primer3DSError.threeDsErrorComponent))")
        XCTAssert(primer3DSContainerError.threeDsErrorDetail == primer3DSError.threeDsErrorDetail, "3DS error detail should be \(String(describing: primer3DSError.threeDsErrorDetail))")
        XCTAssert(primer3DSContainerError.threeDsSErrorVersion == primer3DSError.threeDsSErrorVersion, "3DS error version should be \(String(describing: primer3DSError.threeDsSErrorVersion))")
        XCTAssert(primer3DSContainerError.threeDsSdkTranscationId == primer3DSError.threeDsSdkTranscationId, "3DS error transaction id should be \(String(describing: primer3DSError.threeDsSdkTranscationId))")

        primer3DSError = Primer3DSError.failedToCreateTransaction(error: nsErr)
        primer3DSContainerError = self.createPrimer3DSContainerError(from: primer3DSError,
                                                                     diagnosticsId: diagnosticsId,
                                                                     initProtocolVersion: initProtocolVersion)
        XCTAssert(primer3DSContainerError.initProtocolVersion == initProtocolVersion, "Protocol version should be \(initProtocolVersion)")
        errorDescription = "[\(primer3DSError.errorId)] \(primer3DSError.errorDescription) (diagnosticsId: \(diagnosticsId))"
        XCTAssert(primer3DSContainerError.errorDescription == errorDescription, "Error description should be '\(errorDescription)'")
        XCTAssert(primer3DSContainerError.diagnosticsId == diagnosticsId, "Error diagnosticsId should be '\(diagnosticsId)'")
        XCTAssert(primer3DSContainerError.recoverySuggestion == primer3DSError.recoverySuggestion, "Error recoverySuggestion should be '\(String(describing: primer3DSError.recoverySuggestion))'")
        XCTAssert(primer3DSContainerError.threeDsErrorCode == primer3DSError.threeDsErrorCode, "3DS error code should be \(String(describing: primer3DSError.threeDsErrorCode))")
        XCTAssert(primer3DSContainerError.threeDsErrorType == primer3DSError.threeDsErrorType, "3DS error type should be \(String(describing: primer3DSError.threeDsErrorType))")
        XCTAssert(primer3DSContainerError.threeDsErrorComponent == primer3DSError.threeDsErrorComponent, "3DS error component should be \(String(describing: primer3DSError.threeDsErrorComponent))")
        XCTAssert(primer3DSContainerError.threeDsErrorDetail == primer3DSError.threeDsErrorDetail, "3DS error detail should be \(String(describing: primer3DSError.threeDsErrorDetail))")
        XCTAssert(primer3DSContainerError.threeDsSErrorVersion == primer3DSError.threeDsSErrorVersion, "3DS error version should be \(String(describing: primer3DSError.threeDsSErrorVersion))")
        XCTAssert(primer3DSContainerError.threeDsSdkTranscationId == primer3DSError.threeDsSdkTranscationId, "3DS error transaction id should be \(String(describing: primer3DSError.threeDsSdkTranscationId))")

        primer3DSError = Primer3DSError.initializationError(error: nsErr, warnings: nil)
        primer3DSContainerError = self.createPrimer3DSContainerError(from: primer3DSError,
                                                                     diagnosticsId: diagnosticsId,
                                                                     initProtocolVersion: initProtocolVersion)
        XCTAssert(primer3DSContainerError.initProtocolVersion == initProtocolVersion, "Protocol version should be \(initProtocolVersion)")
        errorDescription = "[\(primer3DSError.errorId)] \(primer3DSError.errorDescription) (diagnosticsId: \(diagnosticsId))"
        XCTAssert(primer3DSContainerError.errorDescription == errorDescription, "Error description should be '\(errorDescription)'")
        XCTAssert(primer3DSContainerError.diagnosticsId == diagnosticsId, "Error diagnosticsId should be '\(diagnosticsId)'")
        XCTAssert(primer3DSContainerError.recoverySuggestion == primer3DSError.recoverySuggestion, "Error recoverySuggestion should be '\(String(describing: primer3DSError.recoverySuggestion))'")
        XCTAssert(primer3DSContainerError.threeDsErrorCode == primer3DSError.threeDsErrorCode, "3DS error code should be \(String(describing: primer3DSError.threeDsErrorCode))")
        XCTAssert(primer3DSContainerError.threeDsErrorType == primer3DSError.threeDsErrorType, "3DS error type should be \(String(describing: primer3DSError.threeDsErrorType))")
        XCTAssert(primer3DSContainerError.threeDsErrorComponent == primer3DSError.threeDsErrorComponent, "3DS error component should be \(String(describing: primer3DSError.threeDsErrorComponent))")
        XCTAssert(primer3DSContainerError.threeDsErrorDetail == primer3DSError.threeDsErrorDetail, "3DS error detail should be \(String(describing: primer3DSError.threeDsErrorDetail))")
        XCTAssert(primer3DSContainerError.threeDsSErrorVersion == primer3DSError.threeDsSErrorVersion, "3DS error version should be \(String(describing: primer3DSError.threeDsSErrorVersion))")
        XCTAssert(primer3DSContainerError.threeDsSdkTranscationId == primer3DSError.threeDsSdkTranscationId, "3DS error transaction id should be \(String(describing: primer3DSError.threeDsSdkTranscationId))")

        primer3DSError = Primer3DSError.initializationError(error: nil, warnings: "I am a warning")
        primer3DSContainerError = self.createPrimer3DSContainerError(from: primer3DSError,
                                                                     diagnosticsId: diagnosticsId,
                                                                     initProtocolVersion: initProtocolVersion)
        XCTAssert(primer3DSContainerError.initProtocolVersion == initProtocolVersion, "Protocol version should be \(initProtocolVersion)")
        errorDescription = "[\(primer3DSError.errorId)] \(primer3DSError.errorDescription) (diagnosticsId: \(diagnosticsId))"
        XCTAssert(primer3DSContainerError.errorDescription == errorDescription, "Error description should be '\(errorDescription)'")
        XCTAssert(primer3DSContainerError.diagnosticsId == diagnosticsId, "Error diagnosticsId should be '\(diagnosticsId)'")
        XCTAssert(primer3DSContainerError.recoverySuggestion == primer3DSError.recoverySuggestion, "Error recoverySuggestion should be '\(String(describing: primer3DSError.recoverySuggestion))'")
        XCTAssert(primer3DSContainerError.threeDsErrorCode == primer3DSError.threeDsErrorCode, "3DS error code should be \(String(describing: primer3DSError.threeDsErrorCode))")
        XCTAssert(primer3DSContainerError.threeDsErrorType == primer3DSError.threeDsErrorType, "3DS error type should be \(String(describing: primer3DSError.threeDsErrorType))")
        XCTAssert(primer3DSContainerError.threeDsErrorComponent == primer3DSError.threeDsErrorComponent, "3DS error component should be \(String(describing: primer3DSError.threeDsErrorComponent))")
        XCTAssert(primer3DSContainerError.threeDsErrorDetail == primer3DSError.threeDsErrorDetail, "3DS error detail should be \(String(describing: primer3DSError.threeDsErrorDetail))")
        XCTAssert(primer3DSContainerError.threeDsSErrorVersion == primer3DSError.threeDsSErrorVersion, "3DS error version should be \(String(describing: primer3DSError.threeDsSErrorVersion))")
        XCTAssert(primer3DSContainerError.threeDsSdkTranscationId == primer3DSError.threeDsSdkTranscationId, "3DS error transaction id should be \(String(describing: primer3DSError.threeDsSdkTranscationId))")

    }

    func test_error_includes_errorId_paymentMethodType() throws {
        let primer3DSError = Primer3DSError.initializationError(error: nil, warnings: "I am a warning")
        let primer3DSContainerError = self.createPrimer3DSContainerError(from: primer3DSError,
                                                                         paymentMethodType: "TEST_PAYMENT_METHOD",
                                                                         diagnosticsId: "diagnosticsId",
                                                                         initProtocolVersion: "initProtocolVersion")

        XCTAssert(primer3DSContainerError.analyticsContext[AnalyticsContextKeys.errorId] as? String == primer3DSContainerError.errorId)
        XCTAssert(primer3DSContainerError.analyticsContext[AnalyticsContextKeys.paymentMethodType] as? String == "TEST_PAYMENT_METHOD")
    }

    func createPrimer3DSContainerError(from primer3DSError: Primer3DSError,
                                       paymentMethodType: String = "",
                                       diagnosticsId: String,
                                       initProtocolVersion: String) -> Primer3DSErrorContainer {
        return Primer3DSErrorContainer.primer3DSSdkError(
            paymentMethodType: paymentMethodType,
            userInfo: nil,
            diagnosticsId: diagnosticsId,
            initProtocolVersion: initProtocolVersion,
            errorInfo: Primer3DSErrorInfo(
                errorId: primer3DSError.errorId,
                errorDescription: primer3DSError.errorDescription,
                recoverySuggestion: primer3DSError.recoverySuggestion,
                threeDsErrorCode: primer3DSError.threeDsErrorCode,
                threeDsErrorType: primer3DSError.threeDsErrorType,
                threeDsErrorComponent: primer3DSError.threeDsErrorComponent,
                threeDsSdkTranscationId: primer3DSError.threeDsSdkTranscationId,
                threeDsSErrorVersion: primer3DSError.threeDsSErrorVersion,
                threeDsErrorDetail: primer3DSError.threeDsErrorDetail))
    }
}
#endif
