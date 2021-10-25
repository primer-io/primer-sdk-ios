//
//  Bank.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 25/10/21.
//

import Foundation

struct Bank: Decodable {
    let id: String?
    let name: String?
    let issuer: String?
    let logoUrlStr: String?
    lazy var logoUrl: URL? = {
        guard let logoUrlStr = logoUrlStr else { return nil }
        return URL(string: logoUrlStr)
    }()
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case issuer
        case logoUrlStr = "logoUrl"
    }
}
