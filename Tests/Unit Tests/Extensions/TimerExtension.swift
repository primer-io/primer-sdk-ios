//
//  TimerExtension.swift
//  PrimerSDK
//
//  Created by Evangelos on 20/9/22.
//

import Foundation
@testable import PrimerSDK

internal extension Timer {

    static func delay(_ timeInterval: TimeInterval) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
                seal.fulfill()
            }
        }
    }
}
