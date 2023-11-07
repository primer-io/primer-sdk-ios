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
    
    func primerRawDataManager(_ rawDataManager: RawDataManager,
                              metadataDidChange metadata: [String : Any]?) {
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
                              willFetchCardMetadataForState cardState: PrimerCardNumberEntryState) {
        onWillFetchCardMetadataForStateCount += 1
        onWillFetchCardMetadataForState?(rawDataManager, cardState)
    }
    
    // MARK: metadata forCardValidationState
    
    var onMetadataForCardValidationState: ((RawDataManager, PrimerCardMetadata, PrimerCardNumberEntryState) -> Void)?
    
    var onMetadataForCardValidationStateCount = 0
    
    func primerRawDataManager(_ rawDataManager: RawDataManager,
                              didReceiveCardMetadata metadata: PrimerCardMetadata,
                              forCardState cardState: PrimerCardNumberEntryState) {
        onMetadataForCardValidationStateCount += 1
        onMetadataForCardValidationState?(rawDataManager, metadata, cardState)
    }
}
