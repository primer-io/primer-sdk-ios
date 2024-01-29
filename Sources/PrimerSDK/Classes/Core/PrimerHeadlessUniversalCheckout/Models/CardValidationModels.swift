////
////  CardValidationModels.swift
////  PrimerSDK
////
////  Created by Jack Newcombe on 18/10/2023.
////
//
//import Foundation
//
//@objc
//public class PrimerCardValidationState: NSObject {
//    public let cardNumber: String
//    
//    init(cardNumber: String) {
//        self.cardNumber = cardNumber
//    }
//}
//
//@objc 
//public class PrimerCardNetwork: NSObject {
//    public let displayName: String
//    public let networkIdentifier: String
//    
//    init(displayName: String, networkIdentifier: String) {
//        self.displayName = displayName
//        self.networkIdentifier = networkIdentifier
//    }
//}
//
//@objc
//public class PrimerCardMetadata: NSObject {
//    public var preferredCardNetwork: PrimerCardNetwork? {
//        return availableCardNetworks.first
//    }
//    
//    public let availableCardNetworks: [PrimerCardNetwork]
//    
//    init(availableCardNetworks: [PrimerCardNetwork]) {
//        self.availableCardNetworks = availableCardNetworks
//    }
//}
