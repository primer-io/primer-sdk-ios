//
//  CheckoutEventsNotifierModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 1/8/22.
//

import Foundation

class CheckoutEventsNotifierModule {
    
    var didStartTokenization: (() -> Void)?
    var didFinishTokenization: (() -> Void)?
    var willPresentPaymentMethodUI: (() -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var willDismissPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    
    func fireDidStartTokenizationEvent() -> Promise<Void> {
        return Promise { seal in
            if self.didStartTokenization != nil {
                self.didStartTokenization!()
            }
            
            seal.fulfill()
        }
    }
    
    func fireDidFinishTokenizationEvent() -> Promise<Void> {
        return Promise { seal in
            if self.didFinishTokenization != nil {
                self.didFinishTokenization!()
            }
            
            seal.fulfill()
        }
    }
    
    func fireWillPresentPaymentMethodUI() -> Promise<Void> {
        return Promise { seal in
            if self.willPresentPaymentMethodUI != nil {
                self.willPresentPaymentMethodUI!()
            }
            
            seal.fulfill()
        }
    }
    
    func fireDidPresentPaymentMethodUI() -> Promise<Void> {
        return Promise { seal in
            if self.didPresentPaymentMethodUI != nil {
                self.didPresentPaymentMethodUI!()
            }
            
            seal.fulfill()
        }
    }
    
    func fireWillDismissPaymentMethodUI() -> Promise<Void> {
        return Promise { seal in
            if self.willDismissPaymentMethodUI != nil {
                self.willDismissPaymentMethodUI!()
            }
            
            seal.fulfill()
        }
    }
    
    func fireDidDismissPaymentMethodUI() -> Promise<Void> {
        return Promise { seal in
            if self.didDismissPaymentMethodUI != nil {
                self.didDismissPaymentMethodUI!()
            }
            
            seal.fulfill()
        }
    }
}
