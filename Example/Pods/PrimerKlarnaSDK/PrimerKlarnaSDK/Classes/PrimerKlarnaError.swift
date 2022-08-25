//
//  PrimerKlarnaError.swift
//  PrimerKlarnaSDK
//
//  Created by Evangelos on 24/8/22.
//

#if canImport(UIKit)
import Foundation

internal protocol PrimerKlarnaErrorProtocol: CustomNSError, LocalizedError {
    var errorId: String { get }
    var exposedError: Error { get }
    var info: [String: String]? { get }
    var diagnosticsId: String { get }
}

public enum PrimerKlarnaError: PrimerKlarnaErrorProtocol {
    
    case userNotApproved(userInfo: [String: String]?)
    case klarnaSdkError(errors: [Error], userInfo: [String: String]?)
    
    var errorId: String {
        switch self {
        case .userNotApproved:
            return "klarna-user-not-approved"
        case .klarnaSdkError:
            return "klarna-sdk-error"
        }
    }
    
    var info: [String : String]? {
        var tmpUserInfo: [String: String] = ["createdAt": Date().toString()]
        
        switch self {
        case .userNotApproved(let userInfo),
                .klarnaSdkError(_, let userInfo):
            tmpUserInfo = tmpUserInfo.merging(userInfo ?? [:]) { (_, new) in new }
            tmpUserInfo["diagnosticsId"] = self.diagnosticsId
        }
        
        return tmpUserInfo
    }
    
    var diagnosticsId: String {
        return UUID().uuidString
    }
    
    public var errorDescription: String? {
        switch self {
        case .userNotApproved:
            return "[\(errorId)] User is not approved to perform Klarna payments (diagnosticsId: \(self.diagnosticsId)"
        case .klarnaSdkError(let errors, _):
            return "[\(errorId)] Multiple errors occured: \(errors.combinedDescription) (diagnosticsId: \(self.diagnosticsId)"
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
            if let primerError = err as? PrimerKlarnaErrorProtocol {
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
