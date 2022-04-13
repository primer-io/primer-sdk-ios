import Foundation

internal protocol ClientSessionServiceProtocol {
    func requestClientSessionWithActions(actionsRequest: ClientSessionActionsRequest, completion: @escaping (PrimerConfiguration?, Error?) -> Void)
    func requestClientSessionWithActions(actionsRequest: ClientSessionActionsRequest) -> Promise<PrimerConfiguration>
}

internal class ClientSessionService: ClientSessionServiceProtocol {
    
    func requestClientSessionWithActions(actionsRequest: ClientSessionActionsRequest, completion: @escaping (PrimerConfiguration?, Error?) -> Void) {
        self.requestClientSessionWithActionsRequest(actionsRequest, completion: completion)
    }
    
    func requestClientSessionWithActions(actionsRequest: ClientSessionActionsRequest) -> Promise<PrimerConfiguration> {
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
    
    private func requestClientSessionWithActionsRequest(_ request: ClientSessionActionsRequest, completion: @escaping (PrimerConfiguration?, Error?) -> Void) {
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.requestClientSessionWithActions(request: request) { result in
            switch result {
            case .success(let configuration):
                completion(configuration, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}
