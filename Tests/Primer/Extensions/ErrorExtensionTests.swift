//
//  ErrorExtensionTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class ErrorExtensionTests: XCTestCase {

    let dummyError: PrimerError = PrimerError.unknown(diagnosticsId: "")

    func testPrimerErrorForInternalErrors() {
        // MARK: Internal errors

        let internalErrorNoData = InternalError.noData()
        switch internalErrorNoData.exposedError {
        case PrimerError.unknown(_, _):
            break
        default:
            XCTFail()
        }

        // MARK: 3DS errors

        let internalError3DSFailureBreak = InternalError.failedToPerform3dsAndShouldBreak(error: dummyError)
        let exposedError3DSFailureBreak = internalError3DSFailureBreak.exposedError

        let missingDependencyError = Primer3DSErrorContainer.missingSdkDependency()
        let internalError3DSFailureContinue = InternalError.failedToPerform3dsButShouldContinue(error: missingDependencyError)
        let exposedError3DSFailureContinue = internalError3DSFailureContinue.exposedError
        switch exposedError3DSFailureContinue {
        case Primer3DSErrorContainer.missingSdkDependency(_):
            break
        default:
            XCTFail()
        }

        // MARK: Underlying errors


        let multipleUnderlyingErrorsError = PrimerError.underlyingErrors(errors: [dummyError, PrimerError.unknown()])

        switch multipleUnderlyingErrorsError.primerError {
        case PrimerError.underlyingErrors(let errors, _):
            XCTAssertEqual(errors.count, 2)
            break
        default:
            XCTFail()
        }

        let zeroUnderlyingErrorsError = PrimerError.underlyingErrors(errors: [])

        switch zeroUnderlyingErrorsError.primerError {
        case PrimerError.unknown(_, _):
            break
        default:
            XCTFail()
        }

    }

    func testCombinedDescriptionForPrimerErrors() {
        let arrayOfErrors: [Error] = [
            dummyError,
            PrimerError.unknown(diagnosticsId: ""),
            PrimerError.unknown(diagnosticsId: "")
        ]

        let singleDescription = { (_: String) in
            "[unknown] Something went wrong (diagnosticsId: )"
        }

        XCTAssertEqual(arrayOfErrors.combinedDescription,
                       "[\(singleDescription("1")) | \(singleDescription("2")) | \(singleDescription("3"))]")
    }

    func testCombinedDescriptionForNSErrors() {
        let arrayOfErrors: [NSError] = [
            NSError(domain: "domain1", code: 1, userInfo: nil),
            NSError(domain: "domain2", code: 2, userInfo: nil),
            NSError(domain: "domain3", code: 3, userInfo: nil)
        ]

        let singleDescription = { (domain: String, code: Int) in
            "Domain: \(domain), Code: \(code), Description: The operation couldn’t be completed. (\(domain) error \(code).)"
        }

        let desc1 = singleDescription("domain1", 1)
        let desc2 = singleDescription("domain2", 2)
        let desc3 = singleDescription("domain3", 3)

        XCTAssertEqual(arrayOfErrors.map { $0 as Error }.combinedDescription,
                       "[\(desc1) | \(desc2) | \(desc3)]")
    }

    func testIsNetworkError_WithNetworkErrors_ShouldReturnTrue() {
        let networkErrorCodes = [
            NSURLErrorTimedOut,
            NSURLErrorCannotFindHost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorInternationalRoamingOff,
            NSURLErrorCallIsActive,
            NSURLErrorDataNotAllowed,
            NSURLErrorRequestBodyStreamExhausted,
            NSURLErrorBadServerResponse,
            NSURLErrorBadURL,
            NSURLErrorCancelled,
            NSURLErrorCannotCloseFile,
            NSURLErrorCannotCreateFile,
            NSURLErrorCannotDecodeContentData,
            NSURLErrorCannotDecodeRawData,
            NSURLErrorCannotLoadFromNetwork,
            NSURLErrorCannotMoveFile,
            NSURLErrorCannotOpenFile,
            NSURLErrorCannotParseResponse,
            NSURLErrorCannotRemoveFile,
            NSURLErrorCannotWriteToFile,
            NSURLErrorClientCertificateRejected,
            NSURLErrorClientCertificateRequired,
            NSURLErrorDataLengthExceedsMaximum,
            NSURLErrorDownloadDecodingFailedMidStream,
            NSURLErrorDownloadDecodingFailedToComplete,
            NSURLErrorFileDoesNotExist,
            NSURLErrorFileIsDirectory,
            NSURLErrorHTTPTooManyRedirects,
            NSURLErrorNoPermissionsToReadFile,
            NSURLErrorRedirectToNonExistentLocation,
            NSURLErrorResourceUnavailable,
            NSURLErrorServerCertificateHasBadDate,
            NSURLErrorServerCertificateHasUnknownRoot,
            NSURLErrorServerCertificateNotYetValid,
            NSURLErrorServerCertificateUntrusted,
            NSURLErrorSecureConnectionFailed,
            NSURLErrorUnsupportedURL,
            NSURLErrorUserAuthenticationRequired,
            NSURLErrorUserCancelledAuthentication,
            NSURLErrorZeroByteResource
        ]

        networkErrorCodes.forEach { code in
            let nsError = NSError(domain: NSURLErrorDomain, code: code, userInfo: nil)
            XCTAssertTrue(nsError.isNetworkError, "Expected error code \(code) to be identified as a network error")
        }
    }

    func testIsNetworkError_WithNonNetworkError_ShouldReturnFalse() {
        let nonNetworkError = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)
        XCTAssertFalse(nonNetworkError.isNetworkError, "Expected non-network error to not be identified as a network error")

        let differentDomainError = NSError(domain: "CustomDomain", code: NSURLErrorTimedOut, userInfo: nil)
        XCTAssertFalse(differentDomainError.isNetworkError, "Expected error from a different domain to not be identified as a network error")
    }

}
