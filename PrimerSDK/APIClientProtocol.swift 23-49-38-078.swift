
import Foundation

protocol APIClientProtocol {
    func get<T: Decodable>(url: URL, completion: ((T) -> Void)?)
    func post<T: Decodable>(url: URL, body: Encodable, completion: ((T) -> Void)?)
}
