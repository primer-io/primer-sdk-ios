//
//  PrimerEventEmitter.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/6/23.
//

import Foundation

class PrimerEventEmitter {
    
    weak private(set) var paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator!
    var onPaymentMethodFlowWillStart: (() -> Void)?
    var onPaymentMethodFlowDidStart: (() -> Void)?
    var onPaymentMethodFlowDidFinish: (() -> Void)?
    var onClientSessionWillUpdate: (() -> Void)?
    var onClientSessionDidUpdate: (() -> Void)?
    var onPaymentShouldGetCreated: (() -> Void)?
    var onPaymentWillGetCreated: (() -> Void)?
    var onPaymentMethodUIWillGetPresented: (() -> Void)?
    var onPaymentMethodUIDidGetPresented: (() -> Void)?
    var onTokenizationWillStart: (() -> Void)?
    var onTokenizationDidStart: (() -> Void)?
    var onTokenizationDidFinish: (() -> Void)?
    var onPaymentWillStart: (() -> Void)?
    var onPaymentDidStart: (() -> Void)?
    var onPaymentDidFinish: (() -> Void)?
    var onPaymentResumeWillStart: (() -> Void)?
    var onPaymentResumeDidStart: (() -> Void)?
    var onPaymentResumeDidFinish: (() -> Void)?
    var onPaymentMethodUIWillGetDismissed: (() -> Void)?
    var onPaymentMethodUIDidGetDismissed: (() -> Void)?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator) {
        self.paymentMethodOrchestrator = paymentMethodOrchestrator
    }
    
    func fireWillStartPaymentMethodFlowEvent() {
        self.onPaymentMethodFlowWillStart?()
    }
    
    func fireDidStartPaymentMethodFlowEvent() {
        self.onPaymentMethodFlowDidStart?()
    }
    
    func fireWillUpdateClientSessionEvent() {
        self.onClientSessionWillUpdate?()
    }
    
    func fireDidUpdateClientSessionEvent() {
        self.onClientSessionDidUpdate?()
    }
    
    func fireShouldCreatePaymentEvent() {
        self.onPaymentShouldGetCreated?()
    }

    func fireWillCreatePaymentEvent() {
        self.onPaymentWillGetCreated?()
    }
    
    func fireWillPresentPaymentMethodUIEvent() {
        self.onPaymentMethodUIWillGetPresented?()
    }
    
    func fireDidPresentPaymentMethodUIEvent() {
        PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.paymentMethodOrchestrator.paymentMethodConfig.type)
        self.onPaymentMethodUIDidGetPresented?()
    }
    
    func fireWillStartTokenizationEvent() {
        self.onTokenizationWillStart?()
    }
    
    func fireDidStartTokenizationEvent() {
        self.onTokenizationDidStart?()
    }
    
    func fireDidFinishTokenizationEvent() {
        self.onTokenizationDidFinish?()
    }
    
    func fireWillStartPaymentCreationEvent() {
        self.onPaymentWillStart?()
    }
    
    func fireDidStartPaymentCreationEvent() {
        self.onPaymentDidStart?()
    }
    
    func fireDidFinishPaymentCreationEvent() {
        self.onPaymentDidFinish?()
    }
    
    func fireWillStartPaymentResumeEvent() {
        self.onPaymentResumeWillStart?()
    }
    
    func fireDidStartPaymentResumeEvent() {
        self.onPaymentResumeDidStart?()
    }
    
    func fireDidFinishPaymentResumeEvent() {
        self.onPaymentResumeDidFinish?()
    }
    
    func fireWillDismissPaymentMethodUIEvent() {
        self.onPaymentMethodUIWillGetDismissed?()
    }
    
    func fireDidDismissPaymentMethodUIEvent() {
        self.onPaymentMethodUIDidGetDismissed?()
    }
    
    func fireDidFinishPaymentMethodFlowEvent() {
        self.onPaymentMethodFlowDidFinish?()
    }
}
