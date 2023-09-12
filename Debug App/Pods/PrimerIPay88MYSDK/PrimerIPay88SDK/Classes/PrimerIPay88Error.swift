//
//  PrimerIPay88Error.swift
//  PrimerIPay88SDK
//
//  Created by Evangelos on 12/12/22.
//

#if canImport(UIKit)

import Foundation

internal protocol PrimerIPay88ErrorProtocol: CustomNSError, LocalizedError {
    
    var errorId: String { get }
    var exposedError: Error { get }
    var info: [String: String]? { get }
    var diagnosticsId: String { get }
}

public enum PrimerIPay88Error: PrimerIPay88ErrorProtocol {
    
    case iPay88Error(description: String, userInfo: [String: String]?)
    
    var errorId: String {
        switch self {
        case .iPay88Error:
            return "iPay88"
        }
    }
    
    var info: [String : String]? {
        var tmpUserInfo: [String: String] = ["createdAt": Date().toString()]
        
        switch self {
        case .iPay88Error(let description, let userInfo):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
            tmpUserInfo["description"] = description
            tmpUserInfo["diagnosticsId"] = self.diagnosticsId
        }
        
        return tmpUserInfo
    }
    
    var diagnosticsId: String {
        return UUID().uuidString
    }
    
    public var errorDescription: String? {
        switch self {
        case .iPay88Error(let description, _):
            return "[\(errorId)] iPay88 failed with error \(description) (diagnosticsId: \(self.diagnosticsId))"
        }
    }
    
    var exposedError: Error {
        return self
    }
}

fileprivate extension Date {
    
    func toString(withFormat f: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ", timeZone: TimeZone? = nil, calendar: Calendar? = nil) -> String {
        let df = DateFormatter()
        df.dateFormat = f
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = timeZone == nil ? TimeZone.current : timeZone!
        df.calendar = calendar == nil ? Calendar(identifier: .gregorian) : calendar!
        return df.string(from: self)
    }
}

fileprivate extension Array where Element == Error {
    
    var combinedDescription: String {
        var message: String = ""
        
        self.forEach { err in
            if let primerError = err as? PrimerIPay88ErrorProtocol {
                message += "\(primerError.localizedDescription) | "
            } else {
                let nsErr = err as NSError
                message += "Domain: \(nsErr.domain), Code: \(nsErr.code), Description: \(nsErr.localizedDescription)  | "
            }
        }
        
        if message.hasSuffix(" | ") {
            message = String(message.dropLast(3))
        }
        
        return "[\(message)]"
    }
}

#endif
