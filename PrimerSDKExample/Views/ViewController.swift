import UIKit
import PrimerSDK
import AuthenticationServices

class ViewController: UIViewController  {
    
    let button = UIButton()
    
    override func viewDidLoad() {
        title = "Primer"
        view.backgroundColor = .white
        view.addSubview(button)
        button.setTitle("Go to wallet", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .darkGray
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        button.addTarget(self, action: #selector(presentWallet), for: .touchUpInside)
    }
    
    @objc private func presentWallet() {
        let vc = CheckoutViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
}


//MARK: API
struct AuthorizationRequest: Encodable {
    let token: String
    let amount: Int
    let type: String
}

enum NetworkError: Error {
    case missingParams
    case unauthorised
    case timeout
    case serverError
    case invalidResponse
    case serializationError
}

extension UIViewController {
    
    func callApi(_ req: URLRequest, completion: @escaping (_ result: Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: req, completionHandler: { (data, response, err) in
            
            if err != nil {
                completion(.failure(NetworkError.serverError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            if (httpResponse.statusCode < 200 || httpResponse.statusCode > 399) {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            completion(.success(data))
            
        }).resume()
    }
    
}
