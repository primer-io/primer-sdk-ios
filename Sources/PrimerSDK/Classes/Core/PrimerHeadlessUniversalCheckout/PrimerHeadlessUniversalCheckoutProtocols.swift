//
//  PrimerHeadlessUniversalCheckoutProtocols.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

import Foundation
import UIKit

// swiftlint:disable type_name
// swiftlint:disable line_length

@objc
public protocol PrimerHeadlessUniversalCheckoutUIDelegate {
    @objc optional func primerHeadlessUniversalCheckoutUIDidStartPreparation(for paymentMethodType: String)
    @objc optional func primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for paymentMethodType: String)
    @available(*, deprecated, message: "use `primerHeadlessUniversalCheckoutUIDidDismissPaymentMethod` instead")
    @objc optional func primerHeadlessUniveraslCheckoutUIDidDismissPaymentMethod()
    @objc optional func primerHeadlessUniversalCheckoutUIDidDismissPaymentMethod()
}

@objc
public protocol PrimerHeadlessUniversalCheckoutDelegate {

    @objc func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData)

    @objc optional func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod])
    @objc optional func primerHeadlessUniversalCheckoutDidStartTokenization(for paymentMethodType: String)
    @objc optional func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData,
                                                                                decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void)
    @objc optional func primerHeadlessUniversalCheckoutDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void)
    @objc optional func primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?)
    @objc optional func primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?)
    @objc optional func primerHeadlessUniversalCheckoutDidFail(withError err: Error, checkoutData: PrimerCheckoutData?)
    @objc optional func primerHeadlessUniversalCheckoutWillUpdateClientSession()
    @objc optional func primerHeadlessUniversalCheckoutDidUpdateClientSession(_ clientSession: PrimerClientSession)
    @objc optional func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void)
}
// swiftlint:enable type_name
// swiftlint:enable line_length
