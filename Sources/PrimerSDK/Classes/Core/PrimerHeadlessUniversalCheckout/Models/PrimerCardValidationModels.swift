//
//  PrimerCardValidationModels.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 30/10/2023.
//

import Foundation

@objc
public enum PrimerCardValidationSource: Int {
    case local
    case remote
}

@objc
public class PrimerCardNumberEntryState: NSObject {
    public let cardNumber: String
    
    init(cardNumber: String) {
        self.cardNumber = cardNumber
    }
}

@objc
public class PrimerCardNetwork: NSObject {
    public let displayName: String
    public let network: CardNetwork
    
    init(displayName: String, network: CardNetwork) {
        self.displayName = displayName
        self.network = network
    }
}

@objc
public class PrimerCardNumberEntryMetadata: NSObject {
        
    public var preferredCardNetwork: PrimerCardNetwork? {
        return availableCardNetworks.first
    }
    
    public let source: PrimerCardValidationSource

    public let availableCardNetworks: [PrimerCardNetwork]
        
    init(source: PrimerCardValidationSource,
         availableCardNetworks: [PrimerCardNetwork]) {
        self.source = source
        self.availableCardNetworks = availableCardNetworks
    }
}
