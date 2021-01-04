import Foundation

enum APIError: Error {
    case nullResponse
    case statusError
    case postError
}

class APIClient: APIClientProtocol {
    func get(_ token: ClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("1.0.0-beta.0", forHTTPHeaderField: "Primer-SDK-Version")
        request.addValue("IOS_NATIVE", forHTTPHeaderField: "Primer-SDK-Client")
        
        if let tokenVal = token?.accessToken {
            request.addValue(tokenVal, forHTTPHeaderField: "Primer-Client-Token")
        }
        
        URLSession.shared.dataTask(with: request, completionHandler: {
            (data, response, err) in
            
            if let err = err {
                print("API GET request failed:", err)
                return
            }
            
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
    
    func delete(_ token: ClientToken?, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("1.0.0-beta.0", forHTTPHeaderField: "Primer-SDK-Version")
        request.addValue("IOS_NATIVE", forHTTPHeaderField: "Primer-SDK-Client")
        
        if let tokenVal = token?.accessToken {
            request.addValue(tokenVal, forHTTPHeaderField: "Primer-Client-Token")
        }
        
        URLSession.shared.dataTask(with: request, completionHandler: {
            (data, response, err) in
            
            if let err = err {
                print("API DELETE request failed:", err)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            
            print("statusCode: \(httpResponse.statusCode)")
            
            if (httpResponse.statusCode < 200 || httpResponse.statusCode > 399) {
                return
            }
            
            guard let data = data else { return }
            
            completion(.success(data))
            
        }).resume()
    }
    
    func post<T: Encodable>(_ token: ClientToken?, body: T, url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("1.0.0-beta.0", forHTTPHeaderField: "Primer-SDK-Version")
        request.addValue("IOS_NATIVE", forHTTPHeaderField: "Primer-SDK-Client")
        
        if let tokenVal = token?.accessToken {
            request.addValue(tokenVal, forHTTPHeaderField: "Primer-Client-Token")
        }
        
        do {
            let jsonBody = try JSONEncoder().encode(body)
            request.httpBody = jsonBody
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
            print("description: \(httpResponse.description)")
            
            if (httpResponse.statusCode < 200 || httpResponse.statusCode > 399) {
                print("❌ status error:", httpResponse.statusCode)
                completion(.failure(APIError.statusError))
                return
            }
            
            guard let data = data else { return }
            
            completion(.success(data))
            
        }).resume()
    }
}
