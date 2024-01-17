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
    
    convenience init(network: CardNetwork) {
        self.init(
            displayName: network.validation?.niceType ??
                network.rawValue.lowercased().capitalized.replacingOccurrences(of: "_", with: " "),
            network: network
        )
    }
    
    convenience init?(network: CardNetwork?) {
        guard let network = network else { return nil }
        self.init(network: network)
    }
}

@objc
public class PrimerCardNetworksMetadata: NSObject {
    public let items: [PrimerCardNetwork]
    public let preferred: PrimerCardNetwork?
    
    init(items: [PrimerCardNetwork], preferred: PrimerCardNetwork?) {
        self.items = items
        self.preferred = preferred
    }
}

@objc
public class PrimerCardNumberEntryMetadata: NSObject, PrimerPaymentMethodMetadata {
    
    public let source: PrimerCardValidationSource

    public let selectableCardNetworks: PrimerCardNetworksMetadata?
    
    public let detectedCardNetworks: PrimerCardNetworksMetadata
        
    init(source: PrimerCardValidationSource,
         selectableCardNetworks: [PrimerCardNetwork]?,
         detectedCardNetworks: [PrimerCardNetwork]) {
        self.source = source
        
        if source == .remote, let selectableCardNetworks = selectableCardNetworks, !selectableCardNetworks.isEmpty {
            self.selectableCardNetworks = PrimerCardNetworksMetadata(
                items: selectableCardNetworks,
                preferred: selectableCardNetworks.first
            )
        } else {
            self.selectableCardNetworks = nil
        }
        
        let preferredNetwork = [CardNetwork].allowedCardNetworks.first {
            detectedCardNetworks.map { $0.network }.contains($0)
        }
        self.detectedCardNetworks = PrimerCardNetworksMetadata(
            items: detectedCardNetworks,
            preferred: PrimerCardNetwork(network: preferredNetwork)
        )
    }
}
