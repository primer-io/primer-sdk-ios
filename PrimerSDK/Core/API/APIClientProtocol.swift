import Foundation

protocol APIClientProtocol {
    func get(_ token: ClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void))
    func delete(_ token: ClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void))
    func post<T: Encodable>(_ token: ClientToken?, body: T, url: URL, completion: @escaping ((Result<Data, Error>) -> Void))
}

class MockAPIClient: APIClientProtocol {
    
    let response: Data?
    let throwsError: Bool
    
    init(with response: Data? = nil, throwsError: Bool = false) {
        self.response = response
        self.throwsError = throwsError
    }
    
    func get(_ token: ClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        guard let response = response else { return }
        completion(.success(response))
    }
    
    func delete(_ token: ClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        guard let response = response else { return }
        completion(.success(response))
    }
    
    func post<T>(_ token: ClientToken?, body: T, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) where T : Encodable {
        guard let response = response else { return }
        completion(.success(response))
    }
    
}
