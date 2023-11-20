//
//  NolPayAnalyticsEvents.swift
//  PrimerSDK
//
//  Created by Boris on 19.9.23..
//

import Foundation

struct NolPayAnalyticsConstants {
    // link component
    static let LINK_CARD_START_METHOD = "NolPayLinkCardComponent.start()"
    static let LINK_CARD_UPDATE_COLLECTED_DATA_METHOD = "NolPayLinkCardComponent.updateCollectedData()"
    static let LINK_CARD_SUBMIT_DATA_METHOD = "NolPayLinkCardComponent.submit()"

    // unlink component
    static let UNLINK_CARD_START_METHOD = "NolPayUnlinkCardComponent.start()"
    static let UNLINK_CARD_UPDATE_COLLECTED_DATA_METHOD = "NolPayUnlinkCardComponent.updateCollectedData()"
    static let UNLINK_CARD_SUBMIT_DATA_METHOD = "NolPayUnlinkCardComponent.submit()"

    // list cards component
    static let LINKED_CARDS_GET_CARDS_METHOD = "NolPayLinkedCardsComponent.getLinkedCards()"

    // payment component
    static let PAYMENT_START_METHOD = "NolPayStartPaymentComponent.start()"
    static let PAYMENT_UPDATE_COLLECTED_DATA_METHOD = "NolPayStartPaymentComponent.updateCollectedData()"
    static let PAYMENT_SUBMIT_DATA_METHOD = "NolPayStartPaymentComponent.submit()"
    
    // params
    static let CATEGORY_KEY = "category"
    static let CATEGORY_VALUE = "NOL_PAY"
}
