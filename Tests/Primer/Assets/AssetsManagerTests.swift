//
//  AssetsManagerTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 14/11/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class AssetsManagerTests: XCTestCase {

    typealias AssetsManager = PrimerHeadlessUniversalCheckout.AssetsManager

    override func setUpWithError() throws {
        SDKSessionHelper.setUp()
    }

    override func tearDownWithError() throws {
        SDKSessionHelper.tearDown()
    }

    func testCardAssets() throws {

        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .cartesBancaires)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .discover)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .masterCard)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .visa)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .amex)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .elo)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .diners)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .jcb)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .maestro)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .mir)?.cardImage)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(for: .unknown)?.cardImage)

    }

    func testGetNetworkAssetForTokenData() throws {
        XCTAssertEqual(AssetsManager.getCardNetworkAsset(tokenData: .visaNetworkToken)?.cardNetwork, .visa)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(tokenData: .visaNetworkToken)?.cardImage)

        XCTAssertEqual(AssetsManager.getCardNetworkAsset(tokenData: .mcNetworkToken)?.cardNetwork, .masterCard)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(tokenData: .mcNetworkToken)?.cardImage)

        XCTAssertEqual(AssetsManager.getCardNetworkAsset(tokenData: .cbNetworkToken)?.cardNetwork, .cartesBancaires)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(tokenData: .cbNetworkToken)?.cardImage)

        XCTAssertEqual(AssetsManager.getCardNetworkAsset(tokenData: .visaBinNetworkToken)?.cardNetwork, .visa)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(tokenData: .visaBinNetworkToken)?.cardImage)

        XCTAssertEqual(AssetsManager.getCardNetworkAsset(tokenData: .visafirstSixToken)?.cardNetwork, .visa)
        XCTAssertNotNil(AssetsManager.getCardNetworkAsset(tokenData: .visafirstSixToken)?.cardImage)
    }
}

private extension Response.Body.Tokenization.PaymentInstrumentData {
    static let visaNetworkToken = Self.init(paypalBillingAgreementId: nil,
                                            first6Digits: nil,
                                            last4Digits: nil,
                                            expirationMonth: nil,
                                            expirationYear: nil,
                                            cardholderName: nil,
                                            network: "VISA",
                                            isNetworkTokenized: nil,
                                            klarnaCustomerToken: nil,
                                            sessionData: nil,
                                            externalPayerInfo: nil,
                                            shippingAddress: nil,
                                            binData: nil,
                                            threeDSecureAuthentication: nil,
                                            gocardlessMandateId: nil,
                                            authorizationToken: nil,
                                            mx: nil,
                                            currencyCode: nil,
                                            productId: nil,
                                            paymentMethodConfigId: nil,
                                            paymentMethodType: "PAYMENT_CARD",
                                            sessionInfo: nil)

    static let mcNetworkToken = Self.init(paypalBillingAgreementId: nil,
                                          first6Digits: nil,
                                          last4Digits: nil,
                                          expirationMonth: nil,
                                          expirationYear: nil,
                                          cardholderName: nil,
                                          network: "MASTERCARD",
                                          isNetworkTokenized: nil,
                                          klarnaCustomerToken: nil,
                                          sessionData: nil,
                                          externalPayerInfo: nil,
                                          shippingAddress: nil,
                                          binData: nil,
                                          threeDSecureAuthentication: nil,
                                          gocardlessMandateId: nil,
                                          authorizationToken: nil,
                                          mx: nil,
                                          currencyCode: nil,
                                          productId: nil,
                                          paymentMethodConfigId: nil,
                                          paymentMethodType: "PAYMENT_CARD",
                                          sessionInfo: nil)

    static let cbNetworkToken = Self.init(paypalBillingAgreementId: nil,
                                          first6Digits: nil,
                                          last4Digits: nil,
                                          expirationMonth: nil,
                                          expirationYear: nil,
                                          cardholderName: nil,
                                          network: "CARTES_BANCAIRES",
                                          isNetworkTokenized: nil,
                                          klarnaCustomerToken: nil,
                                          sessionData: nil,
                                          externalPayerInfo: nil,
                                          shippingAddress: nil,
                                          binData: nil,
                                          threeDSecureAuthentication: nil,
                                          gocardlessMandateId: nil,
                                          authorizationToken: nil,
                                          mx: nil,
                                          currencyCode: nil,
                                          productId: nil,
                                          paymentMethodConfigId: nil,
                                          paymentMethodType: "PAYMENT_CARD",
                                          sessionInfo: nil)

    static let visaBinNetworkToken = Self.init(paypalBillingAgreementId: nil,
                                               first6Digits: nil,
                                               last4Digits: nil,
                                               expirationMonth: nil,
                                               expirationYear: nil,
                                               cardholderName: nil,
                                               network: nil,
                                               isNetworkTokenized: nil,
                                               klarnaCustomerToken: nil,
                                               sessionData: nil,
                                               externalPayerInfo: nil,
                                               shippingAddress: nil,
                                               binData: BinData(network: "VISA"),
                                               threeDSecureAuthentication: nil,
                                               gocardlessMandateId: nil,
                                               authorizationToken: nil,
                                               mx: nil,
                                               currencyCode: nil,
                                               productId: nil,
                                               paymentMethodConfigId: nil,
                                               paymentMethodType: "PAYMENT_CARD",
                                               sessionInfo: nil)

    static let visafirstSixToken = Self.init(paypalBillingAgreementId: nil,
                                               first6Digits: "401288",
                                               last4Digits: nil,
                                               expirationMonth: nil,
                                               expirationYear: nil,
                                               cardholderName: nil,
                                               network: nil,
                                               isNetworkTokenized: nil,
                                               klarnaCustomerToken: nil,
                                               sessionData: nil,
                                               externalPayerInfo: nil,
                                               shippingAddress: nil,
                                               binData: nil,
                                               threeDSecureAuthentication: nil,
                                               gocardlessMandateId: nil,
                                               authorizationToken: nil,
                                               mx: nil,
                                               currencyCode: nil,
                                               productId: nil,
                                               paymentMethodConfigId: nil,
                                               paymentMethodType: "PAYMENT_CARD",
                                               sessionInfo: nil)
}
