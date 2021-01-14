import UIKit
import AuthenticationServices
import SafariServices

enum OAuthError: Error {
    case invalidURL
}

class OAuthViewController: UIViewController {
    let indicator = UIActivityIndicatorView()
    let viewModel: OAuthViewModelProtocol
    var session: Any?
    
    weak var router: RouterDelegate?
    
    init(with viewModel: OAuthViewModelProtocol, router: RouterDelegate?) {
        self.router = router
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { print("🧨 destroying:", self.self) }
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        indicator.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewModel.generateOAuthURL(with: { [weak self] result in
            switch result {
            case .failure(let error): print(error)
            case .success(let urlString):
                DispatchQueue.main.async {
                    if #available(iOS 13.0, *) {
                        self?.createPaymentInstrument(urlString)
                    } else {
                        self?.createPaymentInstrumentLegacy(urlString)
                    }
                }
            }
        })
    }
    
    @available(iOS 13.0, *)
    func createPaymentInstrument(_ urlString: String) {
        var session: ASWebAuthenticationSession?
        
        guard let authURL = URL(string: urlString) else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "primer",
            completionHandler: { [weak self] (url, error) in
                
                if (error != nil) {
                    self?.dismiss(animated: true, completion: nil)
                    return
                }
                
                self?.onOAuthCompleted(callbackURL: url, error: error)
            }
        )
        
        session?.presentationContextProvider = self
        
        self.session = session
        
        session?.start()
    }
    
    @available(iOS, deprecated: 12.0)
    func createPaymentInstrumentLegacy(_ urlString: String) {
        
        var session: SFAuthenticationSession?
        
        guard let authURL = URL(string: urlString) else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        session = SFAuthenticationSession(
            url: authURL,
            callbackURLScheme: "primer",
            completionHandler: { [weak self] (url, error) in
                
                if (error != nil) {
                    self?.dismiss(animated: true, completion: nil)
                    return
                }
                
                self?.onOAuthCompleted(callbackURL: url, error: error)
            }
        )
        
        session?.start()
        
    }
    
    private func onOAuthCompleted(callbackURL: URL?, error: Error?) {
        viewModel.tokenize(with: { [weak self] error in
            DispatchQueue.main.async {
                
                self?.view.removeFromSuperview()
                
                if (error != nil) {
                    self?.router?.showError()
                    return
                }
                
                self?.router?.showSuccess()
                
            }
        })
    }
}

extension OAuthViewController: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 12.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
    
}
