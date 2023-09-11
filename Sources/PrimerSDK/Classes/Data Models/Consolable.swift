//
//  Consolable.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 19/3/21.
//



import Foundation

@propertyWrapper
struct Consolable<T> {

    var wrappedValue: T {
        didSet {
            #if DEBUG
            log(logLevel: .verbose, message: "Did set \(type(of: wrappedValue))")
            #endif
        }
    }

    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}


