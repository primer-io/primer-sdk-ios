//
//  PrimerEventEmitter.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/6/23.
//

import Foundation

class PrimerEventEmitter {
    
    weak private(set) var paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator!
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator) {
        self.paymentMethodOrchestrator = paymentMethodOrchestrator
    }
    
    func fireWillStartPaymentMethodFlowEvent() {
        
    }
    
    func fireDidStartPaymentMethodFlowEvent() {
        
    }
    
    func fireWillUpdateClientSessionEvent() {
        
    }
    
    func fireDidUpdateClientSessionEvent() {
        
    }
    
    func fireShouldCreatePaymentEvent() {
        
    }
    
    func fireWillCreatePaymentEvent() {
        
    }
    
    func fireWillPresentPaymentMethodUIEvent() {
        
    }
    
    func fireDidPresentPaymentMethodUIEvent() {
        PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.paymentMethodOrchestrator.paymentMethodConfig.type)
    }
    
    func fireWillStartTokenizationEvent() {
        
    }
    
    func fireDidStartTokenizationEvent() {
        
    }
    
    func fireDidFinishTokenizationEvent() {
        
    }
    
    func fireWillStartPaymentCreationEvent() {
        
    }
    
    func fireDidStartPaymentCreationEvent() {
        
    }
    
    func fireDidFinishPaymentCreationEvent() {
        
    }
    
    func fireWillStartPaymentResumeEvent() {
        
    }
    
    func fireDidStartPaymentResumeEvent() {
        
    }
    
    func fireDidFinishPaymentResumeEvent() {
        
    }
    
    func fireWillDismissPaymentMethodUIEvent() {
        
    }
    
    func fireDidDismissPaymentMethodUIEvent() {
        
    }
    
    func fireDidFinishPaymentMethodFlowEvent() {
        
    }
}
