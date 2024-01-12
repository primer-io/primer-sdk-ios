//
//  NolPayAnalyticsEvents.swift
//  PrimerSDK
//
//  Created by Boris on 19.9.23..
//

import Foundation

struct NolPayAnalyticsConstants {

    // Link component
    static let linkCardStartMethod = "NolPayLinkCardComponent.start()"
    static let linkCardUpdateCollectedDataMethod = "NolPayLinkCardComponent.updateCollectedData()"
    static let linkCardSubmitDataMethod = "NolPayLinkCardComponent.submit()"

    // Unlink component
    static let unlinkCardStartMethod = "NolPayUnlinkCardComponent.start()"
    static let unlinkCardUpdateCollectedDataMethod = "NolPayUnlinkCardComponent.updateCollectedData()"
    static let unlinkCardSubmitDataMethod = "NolPayUnlinkCardComponent.submit()"

    // List cards component
    static let linkedCardsGetCardsMethod = "NolPayLinkedCardsComponent.getLinkedCards()"

    // Payment component
    static let paymentStartMethod = "NolPayStartPaymentComponent.start()"
    static let paymentUpdateCollectedDataMethod = "NolPayStartPaymentComponent.updateCollectedData()"
    static let paymentSubmitDataMethod = "NolPayStartPaymentComponent.submit()"
}
