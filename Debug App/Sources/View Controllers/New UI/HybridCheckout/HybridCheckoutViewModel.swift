//
//  HybridCheckoutViewModel.swift
//  Debug App
//
//  Created by Niall Quinn on 22/07/24.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation
import PrimerSDK

class HybridCheckoutViewModel: ObservableObject {
    
    @Published var availablePaymentMethods: [String] = []
    var settings: PrimerSettings
    var clientSession: ClientSessionRequestBody?
    var clientToken: String?
    
    init(availablePaymentMethods: [String], 
         settings: PrimerSettings,
         clientSession: ClientSessionRequestBody? = nil,
         clientToken: String? = nil) {
        self.availablePaymentMethods = availablePaymentMethods
        self.settings = settings
        self.clientSession = clientSession
        self.clientToken = clientToken
    }
    
    func startHeadless() {
        
    }
    
    func stardDropin() {
        
    }
    
    func dropInShowPaymentMethod(_ paymentMethodName: String) {
        
    }
    
}
