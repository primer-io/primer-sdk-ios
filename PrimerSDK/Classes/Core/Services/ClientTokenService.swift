protocol ClientTokenServiceProtocol {
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void)
}

class ClientTokenService: ClientTokenServiceProtocol {
    
    @Dependency private(set) var state: AppStateProtocol
    
    /**
    performs asynchronous call passed in by app developer, decodes the returned Base64 Primer client token string and adds it to shared state.
     */
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        state.settings.clientTokenRequestCallback({ [weak self] result in
            switch result {
            case .failure: completion(PrimerError.ClientTokenNull)
            case .success(let token):
                guard let clientToken = token.clientToken else {
                    return completion(PrimerError.ClientTokenNull)
                }
                self?.state.decodedClientToken = clientToken.decodeClientTokenBase64()
                completion(nil)
            }
        })
    }
    
}

extension String {
    func decodeClientTokenBase64() -> DecodedClientToken {
        let bytes = self.components(separatedBy: ".")
        for element in bytes {
            // decode element, add necessary padding to base64 to ensure it's a multiple of 4 (required by Swift foundation)
            if let decodedData = Data(base64Encoded: element.padding(toLength: ((element.count + 3) / 4) * 4, withPad: "=", startingAt: 0)) {
                let decodedString = String(data: decodedData, encoding: .utf8)!
                if (decodedString.contains("\"accessToken\":")) {
                    do {
                        log(logLevel: .info, title: nil, message: "Decoded string: \(decodedString)", prefix: nil, suffix: nil, bundle: Bundle.self.description(), file: #file, className: String(describing: Self.self), function: #function, line: #line)
                        let token = try JSONDecoder().decode(DecodedClientToken.self, from: decodedData)
                        return token
                    } catch {
                        _ = ErrorHandler.shared.handle(error: error)
                    }
                }
            }
            
        }
        return DecodedClientToken()
    }
}
