//
//  PrimerCardValidationModels.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 30/10/2023.
//

import Foundation

@objc
public protocol PrimerValidationState {}

@objc
public protocol PrimerPaymentMethodMetadata {}

@objc
public enum PrimerCardValidationSource: Int {
    case local
    case localFallback
    case remote
}

@objc
public class PrimerCardNumberEntryState: NSObject, PrimerValidationState {
    public let cardNumber: String
    
    init(cardNumber: String) {
        self.cardNumber = cardNumber
    }
}

@objc
public class PrimerCardNetwork: NSObject {
    public let displayName: String
    public let network: CardNetwork
    
    public var allowed: Bool {
        return [CardNetwork].allowedCardNetworks.contains(network)
    }
    
    init(displayName: String, network: CardNetwork) {
        self.displayName = displayName
        self.network = network
    }
}

@objc
public class PrimerCardNumberEntryMetadata: NSObject, PrimerPaymentMethodMetadata {
        
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
