//
//  ErrorExtensionTests.swift
//
//
//  Created by Jack Newcombe on 10/05/2024.
//

import XCTest
@testable import PrimerSDK

final class ErrorExtensionTests: XCTestCase {

    let dummyError: PrimerError = PrimerError.unknown(userInfo: ["test": "test"], diagnosticsId: "")

    func testPrimerErrorForInternalErrors() {
        // MARK: Internal errors

        let internalErrorNoData = InternalError.noData(userInfo: nil, diagnosticsId: nil)
        switch internalErrorNoData.exposedError {
        case PrimerError.unknown(_, _):
            break
        default:
            XCTFail()
        }

        // MARK: 3DS errors

        let internalError3DSFailureBreak = InternalError.failedToPerform3dsAndShouldBreak(error: dummyError)
        let exposedError3DSFailureBreak = internalError3DSFailureBreak.exposedError
        switch exposedError3DSFailureBreak {
        case PrimerError.unknown(let userInfo, _):
            XCTAssertEqual(userInfo?["test"], "test")
            break
        default:
            XCTFail()
        }

        let internalError3DSFailureContinue = InternalError.failedToPerform3dsButShouldContinue(error:
            Primer3DSErrorContainer.missingSdkDependency(userInfo: nil, diagnosticsId: "")
        )
        let exposedError3DSFailureContinue = internalError3DSFailureContinue.exposedError
        switch exposedError3DSFailureContinue {
        case Primer3DSErrorContainer.missingSdkDependency(_, _):
            break
        default:
            XCTFail()
        }
        

        // MARK: Underlying errors

        let singleUnderlyingErrorsError = PrimerError.underlyingErrors(errors: [dummyError], userInfo: nil, diagnosticsId: "")

        switch singleUnderlyingErrorsError.primerError {
        case PrimerError.unknown(let userInfo, _):
            XCTAssertEqual(userInfo?["test"], "test")
        default:
            XCTFail()
        }

        let multipleUnderlyingErrorsError = PrimerError.underlyingErrors(errors: [
            dummyError,
            PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        ], userInfo: nil, diagnosticsId: "")

        switch multipleUnderlyingErrorsError.primerError {
        case PrimerError.underlyingErrors(let errors, _, _):
            XCTAssertEqual(errors.count, 2)
            break
        default:
            XCTFail()
        }

        let zeroUnderlyingErrorsError = PrimerError.underlyingErrors(errors: [], userInfo: nil, diagnosticsId: "")

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
            PrimerError.unknown(userInfo: nil, diagnosticsId: ""),
            PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        ]

        let singleDescription = { (message: String) in
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

}
