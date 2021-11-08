//
//  Bank.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 25/10/21.
//

import Foundation

struct Bank: Decodable {
    let id: String
    let name: String
    let iconUrlStr: String?
    lazy var iconUrl: URL? = {
        guard let iconUrlStr = iconUrlStr else { return nil }
        return URL(string: iconUrlStr)
    }()
    let disabled: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconUrlStr = "iconUrl"
        case disabled
    }
}
