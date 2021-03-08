import Foundation

protocol APIClientProtocol {
    func get(_ token: DecodedClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void))
    func delete(_ token: DecodedClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void))
    func post<T: Encodable>(_ token: DecodedClientToken?, body: T, url: URL, completion: @escaping ((Result<Data, Error>) -> Void))
}

class MockAPIClient: APIClientProtocol {
    
    let response: Data?
    let throwsError: Bool
    
    init(with response: Data? = nil, throwsError: Bool = false) {
        self.response = response
        self.throwsError = throwsError
    }
    
    func get(_ token: DecodedClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        guard let response = response else { return }
        completion(.success(response))
    }
    
    func delete(_ token: DecodedClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        guard let response = response else { return }
        completion(.success(response))
    }
    
    var postCalled = false
    
    func post<T>(_ token: DecodedClientToken?, body: T, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) where T : Encodable {
        postCalled = true
        if throwsError {
            return completion(.failure(APIError.postError))
        }
        guard let response = response else { return }
        completion(.success(response))
    }
    
}
