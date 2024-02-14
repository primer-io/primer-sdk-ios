//
//  Bin.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 17/10/2023.
//

import Foundation

extension Response.Body {
    class Bin {}
}

extension Response.Body.Bin {
    class Networks: Decodable {
        let networks: [Network]

        init(networks: [Network]) {
            self.networks = networks
        }
    }
}

extension Response.Body.Bin.Networks {
    class Network: Decodable {
        let displayName: String
        let value: String

        init(displayName: String, value: String) {
            self.displayName = displayName
            self.value = value
        }
    }
}
