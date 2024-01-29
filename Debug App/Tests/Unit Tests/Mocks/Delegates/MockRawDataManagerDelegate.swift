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
}
