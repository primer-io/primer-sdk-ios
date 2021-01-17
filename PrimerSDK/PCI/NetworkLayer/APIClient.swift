import Foundation

enum APIError: Error {
    case nullResponse
    case statusError
    case postError
}

enum APIMethod: String {
    case GET = "GET"
    case POST = "POST"
    case DELETE = "DELETE"
    case PUT = "PUT"
}

class APIClient: APIClientProtocol {
    
    private func renderRequest(of method: APIMethod, with url: URL, and token: String?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("1.0.0-beta.0", forHTTPHeaderField: "Primer-SDK-Version")
        request.addValue("IOS_NATIVE", forHTTPHeaderField: "Primer-SDK-Client")
        
        if let token = token {
            request.addValue(token, forHTTPHeaderField: "Primer-Client-Token")
        }
        
        return request
    }
    
    func get(_ token: DecodedClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        
        let request = renderRequest(of: .GET, with: url, and: token?.accessToken)
        
        URLSession.shared.dataTask(with: request, completionHandler: {
            (data, response, err) in
            
            if let err = err { return print("API GET request failed:", err) }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(APIError.nullResponse))
            }
            
            print("statusCode: \(httpResponse.statusCode)")
            
            if (httpResponse.statusCode < 200 || httpResponse.statusCode > 399) {
                return completion(.failure(APIError.statusError))
            }
            
            guard let data = data else { return }
            
            completion(.success(data))
            
        }).resume()
    }
    
    func delete(_ token: DecodedClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        
        let request = renderRequest(of: .DELETE, with: url, and: token?.accessToken)
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, err) in
            
            if let err = err { return print("API DELETE request failed:", err) }
            
            guard let httpResponse = response as? HTTPURLResponse else { return }
            
            print("statusCode: \(httpResponse.statusCode)")
            
            if (httpResponse.statusCode < 200 || httpResponse.statusCode > 399) { return }
            
            guard let data = data else { return }
            
            completion(.success(data))
            
        }).resume()
    }
    
    func post<T: Encodable>(_ token: DecodedClientToken?, body: T, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        
        var request = renderRequest(of: .POST, with: url, and: token?.accessToken)
        
        do {
            let payload = try JSONEncoder().encode(body)
            request.httpBody = payload
        } catch {
            print(error)
        }
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, err) in
            
            if let err = err {
                print("API POST request failed:", err)
                return completion(.failure(APIError.postError))
            }
            
            guard let httpResponse = response as? HTTPURLResponse else { return completion(.failure(APIError.nullResponse)) }
            
            print("statusCode: \(httpResponse.statusCode)")
            
            if (httpResponse.statusCode < 200 || httpResponse.statusCode > 399) {
                completion(.failure(APIError.statusError))
                return
            }
            
            guard let data = data else { return }
            
            completion(.success(data))
            
        }).resume()
    }
}
