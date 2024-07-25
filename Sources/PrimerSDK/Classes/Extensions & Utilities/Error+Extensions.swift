//
//  Error+Extensions.swift
//  PrimerSDK
//
//  Created by Boris on 25.7.24..
//

import Foundation

internal extension Error {
    var isNetworkError: Bool {
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain &&
               (nsError.code == NSURLErrorTimedOut ||
                nsError.code == NSURLErrorCannotFindHost ||
                nsError.code == NSURLErrorCannotConnectToHost ||
                nsError.code == NSURLErrorNetworkConnectionLost ||
                nsError.code == NSURLErrorDNSLookupFailed ||
                nsError.code == NSURLErrorNotConnectedToInternet ||
                nsError.code == NSURLErrorInternationalRoamingOff ||
                nsError.code == NSURLErrorCallIsActive ||
                nsError.code == NSURLErrorDataNotAllowed ||
                nsError.code == NSURLErrorRequestBodyStreamExhausted)
    }
}
