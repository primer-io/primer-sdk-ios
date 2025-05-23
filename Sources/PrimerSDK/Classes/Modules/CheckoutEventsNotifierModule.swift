//
//  CheckoutEventsNotifierModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 1/8/22.
//

import Foundation

final class CheckoutEventsNotifierModule {

    var didStartTokenization: (() -> Void)?
    var didFinishTokenization: (() -> Void)?

    func fireDidStartTokenizationEvent() -> Promise<Void> {
        return Promise { seal in
            if self.didStartTokenization != nil {
                self.didStartTokenization!()
            }

            seal.fulfill()
        }
    }

    func fireDidStartTokenizationEvent() async throws {
        try await fireDidStartTokenizationEvent().async()
    }

    func fireDidFinishTokenizationEvent() -> Promise<Void> {
        return Promise { seal in
            if self.didFinishTokenization != nil {
                self.didFinishTokenization!()
            }

            seal.fulfill()
        }
    }

    func fireDidFinishTokenizationEvent() async throws {
        try await fireDidFinishTokenizationEvent().async()
    }
}
