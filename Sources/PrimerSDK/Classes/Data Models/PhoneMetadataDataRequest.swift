//
//  PhoneMetadataDataRequest.swift
//  PrimerSDK
//
//  Created by Boris on 25.10.23..
//

import Foundation
// Request
extension Request.Body {
    class PhoneMetadata {}
}

extension Request.Body.PhoneMetadata {
    
    struct PhoneMetadataDataRequest: Codable {
        
        let phoneNumber: String
    }
}

// Response
extension Response.Body {
    class PhoneMetadata {}
}

extension Response.Body.PhoneMetadata {
    struct PhoneMetadataDataResponse: Codable {
        
        let isValid: Bool
        let countryCode: String?
        let nationalNumber: String?
    }
}
