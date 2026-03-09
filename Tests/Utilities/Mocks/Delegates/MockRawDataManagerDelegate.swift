//
//  MockRawDataManagerDelegate.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

typealias RawDataManager = PrimerHeadlessUniversalCheckout.RawDataManager

final class MockRawDataManagerDelegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {

    // MARK: metadataDidChange

    var onMetadataDidChange: ((RawDataManager, [String: Any]?) -> Void)?

    func primerRawDataManager(_ rawDataManager: RawDataManager,
                              metadataDidChange metadata: [String: Any]?) {
        onMetadataDidChange?(rawDataManager, metadata)
    }

    // MARK: dataIsValid

    var onDataIsValid: ((RawDataManager, Bool, [Error]?) -> Void)?

    func primerRawDataManager(_ rawDataManager: RawDataManager,
                              dataIsValid isValid: Bool, errors: [Error]?) {
        onDataIsValid?(rawDataManager, isValid, errors)
    }

    // MARK: willFetchCardMetadataForState

    var onWillFetchCardMetadataForState: ((RawDataManager, PrimerCardNumberEntryState) -> Void)?

    var onWillFetchCardMetadataForStateCount = 0

    func primerRawDataManager(_ rawDataManager: RawDataManager,
                              willFetchMetadataForState state: PrimerValidationState) {
        onWillFetchCardMetadataForStateCount += 1
        onWillFetchCardMetadataForState?(rawDataManager, state as! PrimerCardNumberEntryState)
    }

    // MARK: metadata forCardValidationState

    var onMetadataForCardValidationState: ((RawDataManager, PrimerCardNumberEntryMetadata, PrimerCardNumberEntryState) -> Void)?

    var onMetadataForCardValidationStateCount = 0

    func primerRawDataManager(_ rawDataManager: RawDataManager,
                              didReceiveMetadata metadata: PrimerPaymentMethodMetadata,
                              forState state: PrimerValidationState) {
        onMetadataForCardValidationStateCount += 1
        onMetadataForCardValidationState?(rawDataManager,
                                          metadata as! PrimerCardNumberEntryMetadata,
                                          state as! PrimerCardNumberEntryState)
    }

    // MARK: didReceiveBinData

    var onBinDataReceived: ((RawDataManager, PrimerBinData) -> Void)?

    var onBinDataReceivedCount = 0

    func primerRawDataManager(_ rawDataManager: RawDataManager,
                              didReceiveBinData binData: PrimerBinData) {
        onBinDataReceivedCount += 1
        onBinDataReceived?(rawDataManager, binData)
    }
}
