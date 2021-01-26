import UIKit
import PrimerSDK
import AuthenticationServices
import MapKit

protocol ViewControllerDelegate: class {
    func addToken(request: AuthorizationRequest)
}

@available(iOS 13.0, *)
class ViewController: UIViewController  {
    
    let button = UIButton()
    let scanButton = UIButton()
    let image = UIImage(systemName: "creditcard")?.withTintColor(.black, renderingMode: .alwaysOriginal)
    let imageView = UIImageView(image: UIImage(systemName: "creditcard")?.withTintColor(.black, renderingMode: .alwaysOriginal))
    let titleLabel = UILabel()
    let map = MKMapView()
    
    var request: AuthorizationRequest?
    
    override func viewDidLoad() {
        title = "Voi"
        view.backgroundColor = .white
        
        //map
        view.addSubview(map)
        map.translatesAutoresizingMaskIntoConstraints = false
        map.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        map.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        map.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        map.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        //
        let initialLocation = CLLocation(latitude: 51.510067, longitude: -0.133869)
        map.centerToLocation(initialLocation)
        
        // button
        view.addSubview(button)
        button.backgroundColor = .white
        button.layer.cornerRadius = 22
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = .zero
        button.layer.shadowRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -88).isActive = true
        button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        button.addTarget(self, action: #selector(presentWallet), for: .touchUpInside)
        
        //
        let image = UIImage(systemName: "creditcard")?.withTintColor(.black, renderingMode: .alwaysOriginal)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(imageView)
        imageView.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        
        //scanButton
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        //        scanButton.setTitle("SCAN TO RIDE!", for: .normal)
        //        scanButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        //        scanButton.setTitleColor(.white, for: .normal)
        scanButton.layer.cornerRadius = 22
        scanButton.backgroundColor = UIColor(red: 240/255, green: 97/255, blue: 91/255, alpha: 1)
        view.addSubview(scanButton)
        scanButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        scanButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        scanButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        scanButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24).isActive = true
        
        scanButton.addTarget(self, action: #selector(authorizePayment), for: .touchUpInside)
        
        titleLabel.text = "SCAN TO RIDE!"
        titleLabel.font = .systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = .white
        
        scanButton.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: scanButton.centerXAnchor, constant: 16).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: scanButton.centerYAnchor).isActive = true
        
        //
        let image2 = UIImage(systemName: "qrcode.viewfinder")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let imageView2 = UIImageView(image: image2)
        imageView2.translatesAutoresizingMaskIntoConstraints = false
        scanButton.addSubview(imageView2)
        imageView2.centerYAnchor.constraint(equalTo: scanButton.centerYAnchor).isActive = true
        imageView2.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -4).isActive = true
    }
    
    @objc private func presentWallet() {
        let vc = CheckoutViewController()
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func authorizePayment() {
        let indicator = UIActivityIndicatorView()
        
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)
        indicator.color = UIColor(red: 240/255, green: 97/255, blue: 91/255, alpha: 1)
        indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        indicator.startAnimating()
        
        //
        guard let body = request else { return }
        guard let url = URL(string: "http://localhost:8020/authorize") else { return }
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return
        }
        
        callApi(request, completion: { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure: return
                case .success:
                    indicator.removeFromSuperview()
                    let alert = UIAlertController(title: "Success!", message: "Your payment was successful.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
                        action in
                        // Called when user taps outside
                    }))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        })
    }
    
}

private extension MKMapView {
    func centerToLocation(
        _ location: CLLocation,
        regionRadius: CLLocationDistance = 1000
    ) {
        let coordinateRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
}

@available(iOS 13.0, *)
extension ViewController: ViewControllerDelegate {
    func addToken(request: AuthorizationRequest) {
        self.request = request
    }
}


















///
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
