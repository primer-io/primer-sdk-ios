import UIKit
import AuthenticationServices

class OAuthViewController: UIViewController {
    let indicator = UIActivityIndicatorView()
    let viewModel: OAuthViewModelProtocol
    let transitionDelegate = TransitionDelegate()
    var session: Any?
    
    init(with viewModel: OAuthViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
        view.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        addLoadingView(indicator)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewModel.generateOAuthURL(with: { result in
            switch result {
            case .failure(let error): print(error)
            case .success(let urlString):
                DispatchQueue.main.async {
                    if #available(iOS 13.0, *) {
                        self.createPaymentInstrument(urlString)
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
        })
    }
    
    @available(iOS 13.0, *)
    func createPaymentInstrument(_ urlString: String) {
        var session: ASWebAuthenticationSession?
        guard let authURL = URL(string: urlString) else { return }
        session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "primer",
            completionHandler: onOAuthCompleted
        )
        session?.presentationContextProvider = self
        // attach session to view controller
        self.session = session
        session?.start()
    }
    
    private func onOAuthCompleted(callbackURL: URL?, error: Error?) {
        viewModel.tokenize(with: { error in DispatchQueue.main.async { self.showModal(error) } } )
    }
}

extension OAuthViewController: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 12.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}
