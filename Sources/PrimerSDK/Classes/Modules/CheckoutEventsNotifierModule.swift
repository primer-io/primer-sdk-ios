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
    
    func fireDidStartTokenizationEvent() -> Promise<Void> {
        return Promise { seal in
            if self.didStartTokenization != nil {
                self.didStartTokenization!()
            }
            
            self.didStartTokenization = nil
            seal.fulfill()
        }
    }
    
    func fireDidFinishTokenizationEvent() -> Promise<Void> {
        return Promise { seal in
            if self.didFinishTokenization != nil {
                self.didFinishTokenization!()
            }
            
            self.didFinishTokenization = nil
            seal.fulfill()
        }
    }
}
