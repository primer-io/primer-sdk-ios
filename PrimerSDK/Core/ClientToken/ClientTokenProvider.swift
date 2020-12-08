//
//  ClientTokenProvider.swift
//  PrimerScannerDemo
//
//  Created by Carl Eriksson on 01/12/2020.
//

import Foundation

class ClientTokenProvider: ClientTokenProviderProtocol {
    
    let clientEncodedToken: String
    
    required init(_ token: String) {
        self.clientEncodedToken = token
    }
    
    func getDecodedClientToken() -> ClientToken {
        let bytes = clientEncodedToken.components(separatedBy: ".")
        for elm in bytes {
            
            // decode element, add necessary padding to base64 to ensure it's a multiple of 4 (required by Swift foundation)
            if let decodedData = Data(base64Encoded: elm.padding(toLength: ((elm.count + 3) / 4) * 4, withPad: "=", startingAt: 0)) {
                let decodedString = String(data: decodedData, encoding: .utf8)!
                if (decodedString.contains("\"accessToken\":")) {
                    do {
                        print(decodedString)
                        let token = try JSONDecoder().decode(ClientToken.self, from: decodedData)
                        return token
                    } catch {
                        print("error!")
                    }
                }
            }
            
        }
        return ClientToken()
    }
}
