//
//  Bin.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 17/10/2023.
//

import Foundation

extension Response.Body {
    struct Bin {}
}

extension Response.Body.Bin {
    struct Networks: Decodable {
        let networks: [Network]
    }
}

extension Response.Body.Bin.Networks {
    struct Network: Decodable {
        let value: String
    }
}
