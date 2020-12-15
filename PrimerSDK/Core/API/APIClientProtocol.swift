
import Foundation

struct Request: Encodable {

}

protocol APIClientProtocol {
    func get(_ token: ClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void))
    func delete(_ token: ClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void))
    func post<T: Encodable>(_ token: ClientToken?, body: T, url: URL, completion: @escaping ((Result<Data, Error>) -> Void))
}
