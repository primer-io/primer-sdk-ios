//
//  ErrorHandler+Delegates.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 21/03/22.
//

import Foundation

final class SendingOnResumeErrorEventHandler: ErrorHandlerProtocol {
    
    func handle(error: Error?) {
        
        guard let error = error else {
            return
        }
        
        PrimerDelegateProxy.onResumeError(error)
    }
}

