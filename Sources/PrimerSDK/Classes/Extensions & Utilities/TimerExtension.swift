//
//  TimerExtension.swift
//  PrimerSDK
//
//  Created by Evangelos on 20/9/22.
//



import Foundation

internal extension Timer {
    
    static func delay(_ timeInterval: TimeInterval) -> Promise<Void> {
        return Promise { seal in
            Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
                seal.fulfill()
            }
        }
    }
}


