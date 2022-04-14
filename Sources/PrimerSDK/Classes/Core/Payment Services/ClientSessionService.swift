import Foundation

internal protocol ClientSessionServiceProtocol {
    func requestClientSessionWithActions(actionsRequest: ClientSessionUpdateRequest, completion: @escaping (PrimerConfiguration?, Error?) -> Void)
    func requestClientSessionWithActions(actionsRequest: ClientSessionUpdateRequest) -> Promise<PrimerConfiguration>
}

internal class ClientSessionService: ClientSessionServiceProtocol {
    
    func requestClientSessionWithActions(actionsRequest: ClientSessionUpdateRequest, completion: @escaping (PrimerConfiguration?, Error?) -> Void) {
        self.requestClientSessionWithActionsRequest(actionsRequest, completion: completion)
    }
    
    func requestClientSessionWithActions(actionsRequest: ClientSessionUpdateRequest) -> Promise<PrimerConfiguration> {
        return Promise { seal in
            self.requestClientSessionWithActionsRequest(actionsRequest, completion: { configuration, err in
                if let err = err {
                    seal.reject(err)
                } else if let configuration = configuration {
                    seal.fulfill(configuration)
                }
            })
        }
    }
}

extension ClientSessionService {
    
    // MARK: - API Request
    
    private func requestClientSessionWithActionsRequest(_ request: ClientSessionUpdateRequest, completion: @escaping (PrimerConfiguration?, Error?) -> Void) {
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            completion(nil, nil)
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.requestClientSessionWithActions(clientToken: decodedClientToken, request: request) { result in
            switch result {
            case .success(let configuration):
                completion(configuration, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}
