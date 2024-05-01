//
//  MockPrimerHeadlessUniversalCheckoutDelegate.swift
//
//
//  Created by Jack Newcombe on 01/05/2024.
//

import XCTest
import PrimerSDK

class MockPrimerHeadlessUniversalCheckoutDelegate: PrimerHeadlessUniversalCheckoutDelegate {
    
    // When set, this will cause a test failure if a delegate method is called without the
    // relevant closure being set
    var strictMode: Bool = false

    // MARK: primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods

    var onDidLoadAvailablePaymentMethods: (([PrimerHeadlessUniversalCheckout.PaymentMethod]) -> Void)?

    func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]) {
        if strictMode {
            XCTAssertNotNil(onDidLoadAvailablePaymentMethods)
        }
        onDidLoadAvailablePaymentMethods?(paymentMethods)
    }

    // MARK: primerHeadlessUniversalCheckoutWillUpdateClientSession

    var onWillUpdateClientSession: (() -> Void)?

    func primerHeadlessUniversalCheckoutWillUpdateClientSession() {
        if strictMode {
            XCTAssertNotNil(onWillUpdateClientSession)
        }
        onWillUpdateClientSession?()
    }

    // MARK: primerHeadlessUniversalCheckoutDidUpdateClientSession

    var onDidUpdateClientSession: ((PrimerClientSession) -> Void)?

    func primerHeadlessUniversalCheckoutDidUpdateClientSession(_ clientSession: PrimerClientSession) {
        if strictMode {
            XCTAssertNotNil(onDidUpdateClientSession)
        }
        onDidUpdateClientSession?(clientSession)
    }

    // MARK: primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo

    var onDidReceiveAdditionalInfo: ((PrimerCheckoutAdditionalInfo?) -> Void)?

    func primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        if strictMode {
            XCTAssertNotNil(onDidReceiveAdditionalInfo)
        }
        onDidReceiveAdditionalInfo?(additionalInfo)
    }

    // MARK: primerHeadlessUniversalCheckoutWillCreatePaymentWithData

    typealias CreatePaymentDecisionHandler = (PrimerPaymentCreationDecision) -> Void

    var onWillCreatePaymentWithData: ((PrimerCheckoutPaymentMethodData, CreatePaymentDecisionHandler) -> Void)?

    func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData,
                                                                  decisionHandler: @escaping CreatePaymentDecisionHandler) {
        if strictMode {
            XCTAssertNotNil(onWillCreatePaymentWithData)
        }
        onWillCreatePaymentWithData?(data, decisionHandler)
    }

    // MARK: primerHeadlessUniversalCheckoutDidStartTokenization

    var onDidStartTokenization: ((String) -> Void)?

    func primerHeadlessUniversalCheckoutDidStartTokenization(for paymentMethodType: String) {
        if strictMode {
            XCTAssertNotNil(onDidStartTokenization)
        }
        onDidStartTokenization?(paymentMethodType)
    }

    // MARK: primerHeadlessUniversalCheckoutDidTokenizePaymentMethod

    typealias TokenizePaymentDecisionHandler = (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void

    var onDidTokenizePaymentMethod: ((PrimerPaymentMethodTokenData, TokenizePaymentDecisionHandler) -> Void)?

    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData,
                                                                 decisionHandler: @escaping TokenizePaymentDecisionHandler) {
        if strictMode {
            XCTAssertNotNil(onDidTokenizePaymentMethod)
        }
        onDidTokenizePaymentMethod?(paymentMethodTokenData, decisionHandler)
    }

    // MARK: primerHeadlessUniversalCheckoutDidResumeWith

    typealias ResumeDecisionHandler = (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void

    var onDidResumeWith: ((String, ResumeDecisionHandler) -> Void)?

    func primerHeadlessUniversalCheckoutDidResumeWith(_ resumeToken: String, 
                                                      decisionHandler: @escaping ResumeDecisionHandler) {
        if strictMode {
            XCTAssertNotNil(onDidResumeWith)
        }
        onDidResumeWith?(resumeToken, decisionHandler)
    }

    // MARK: primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData

    var onDidCompleteCheckoutWithData: ((PrimerCheckoutData) -> Void)?

    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerSDK.PrimerCheckoutData) {
        if strictMode {
            XCTAssertNotNil(onDidCompleteCheckoutWithData)
        }
        onDidCompleteCheckoutWithData?(data)
    }

    // MARK: primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo

    var onDidEnterResumePending: ((PrimerCheckoutAdditionalInfo?) -> Void)?

    func primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        if strictMode {
            XCTAssertNotNil(onDidEnterResumePending)
        }
        onDidEnterResumePending?(additionalInfo)
    }

    // MARK: primerHeadlessUniversalCheckoutDidFail

    var onDidFail: ((Error) -> Void)?

    func primerHeadlessUniversalCheckoutDidFail(withError err: Error) {
        if strictMode {
            XCTAssertNotNil(onDidFail)
        }
        onDidFail?(err)
    }

    // MARK:

    var onDidAbort: ((Error) -> Void)?

    func primerHeadlessUniversalCheckoutDidAbort(withMerchantError error: any Error) {
        if strictMode {
            XCTAssertNotNil(onDidAbort)
        }
        onDidAbort?(error)
    }

}

class MockPrimerHeadlessUniversalCheckoutUIDelegate: PrimerHeadlessUniversalCheckoutUIDelegate {

    // When set, this will cause a test failure if a delegate method is called without the
    // relevant closure being set
    var strictMode: Bool = false

    // MARK: primerHeadlessUniversalCheckoutUIDidStartPreparation

    var onUIDidStartPreparation: ((String) -> Void)?

    func primerHeadlessUniversalCheckoutUIDidStartPreparation(for paymentMethodType: String) {
        if strictMode {
            XCTAssertNotNil(onUIDidStartPreparation)
        }
        onUIDidStartPreparation?(paymentMethodType)
    }

    // MARK: primerHeadlessUniversalCheckoutUIDidShowPaymentMethod

    var onUIDidShowPaymentMethod: ((String) -> Void)?

    func primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for paymentMethodType: String) {
        if strictMode {
            XCTAssertNotNil(onUIDidShowPaymentMethod)
        }
        onUIDidShowPaymentMethod?(paymentMethodType)
    }

    // MARK: primerHeadlessUniveraslCheckoutDidDismissPaymentMethod

    var onUIDidDismissPaymentMethod: (() -> Void)?

    func primerHeadlessUniveraslCheckoutUIDidDismissPaymentMethod() {
        if strictMode {
            XCTAssertNotNil(onUIDidDismissPaymentMethod)
        }
        onUIDidDismissPaymentMethod?()
    }
}

class MockPrimerHeadlessUniversalCheckoutRawDataManagerDelegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {
    
    // When set, this will cause a test failure if a delegate method is called without the
    // relevant closure being set
    var strictMode: Bool = false

    // MARK: metadataDidChange

    var onMetadataDidChange: (([String: Any]?) -> Void)?

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String: Any]?) {
        if strictMode {
            XCTAssertNotNil(onMetadataDidChange)
        }
        onMetadataDidChange?(metadata)
    }

    // MARK: dataIsValid errors

    var onDataIsValidErrors: ((Bool, [Error]?) -> Void)?

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?) {
        if strictMode {
            XCTAssertNotNil(onDataIsValidErrors)
        }
        onDataIsValidErrors?(isValid, errors)
    }
}
