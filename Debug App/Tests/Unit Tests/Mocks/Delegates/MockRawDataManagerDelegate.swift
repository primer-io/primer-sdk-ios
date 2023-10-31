//
//  MockRawDataManagerDelegate.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 31/10/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
@testable import PrimerSDK

class MockRawDataManagerDelegate: RawDataManager.Delegate {
    
    // MARK: metadataDidChange
    
    var onMetadataDidChange: ((RawDataManager, [String: Any]?) -> Void)?
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String : Any]?) {
        onMetadataDidChange?(rawDataManager, metadata)
    }
    
    // MARK: dataIsValid
    
    var onDataIsValid: ((RawDataManager, Bool, [Error]?) -> Void)?
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?) {
        onDataIsValid?(rawDataManager, isValid, errors)
    }
    
    // MARK: willFetchCardMetadataForState
    
    var onWillFetchCardMetadataForState: ((RawDataManager, PrimerCardValidationState) -> Void)?
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, willFetchCardMetadataForState cardState: PrimerCardValidationState) {
        onWillFetchCardMetadataForState?(rawDataManager, cardState)
    }
    
    // MARK: metadata forCardValidationState
    
    var onMetadataForCardValidationState: ((RawDataManager, PrimerCardMetadata, PrimerCardValidationState) -> Void)?
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, didReceiveCardMetadata metadata: PrimerCardMetadata, forCardValidationState cardState: PrimerCardValidationState) {
        onMetadataForCardValidationState?(rawDataManager, metadata, cardState)
    }
}
