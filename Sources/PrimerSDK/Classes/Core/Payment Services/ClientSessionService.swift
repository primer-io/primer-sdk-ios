#if canImport(UIKit)

import Foundation

internal protocol ClientSessionServiceProtocol {
    func requestPrimerConfigurationWithActions(actionsRequest: ClientSessionUpdateRequest) -> Promise<PrimerAPIConfiguration>
}

internal class ClientSessionService: ClientSessionServiceProtocol {
    
    func requestPrimerConfigurationWithActions(actionsRequest: ClientSessionUpdateRequest, completion: @escaping (PrimerAPIConfiguration?, Error?) -> Void) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        let api: PrimerAPIClientProtocol = PrimerAPIClient()
        api.requestPrimerConfigurationWithActions(clientToken: decodedClientToken, request: actionsRequest) { result in
            switch result {
            case .success(let configuration):
                completion(configuration, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    func requestPrimerConfigurationWithActions(actionsRequest: ClientSessionUpdateRequest) -> Promise<PrimerAPIConfiguration> {
        return Promise { seal in
            self.requestPrimerConfigurationWithActions(actionsRequest: actionsRequest) { apiConfiguration, err in
                if let err = err {
                    seal.reject(err)
                } else if let apiConfiguration = apiConfiguration {
                    seal.fulfill(apiConfiguration)
                }
            }
        }
    }
    
//    private func requestPrimerConfigurationWithActions(actionsRequest: ClientSessionUpdateRequest, completion: @escaping (PrimerAPIConfiguration?, Error?) -> Void) {
//
//    }
}

#endif
