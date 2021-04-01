#if canImport(UIKit)

import UIKit
import AuthenticationServices
import SafariServices
import WebKit

@available(iOS 11.0, *)
class OAuthViewController: UIViewController {

    @Dependency private(set) var viewModel: OAuthViewModelProtocol
    @Dependency private(set) var theme: PrimerThemeProtocol
    @Dependency private(set) var router: RouterDelegate

    let indicator = UIActivityIndicatorView()
    var session: Any?
    var host: OAuthHost

    init(host: OAuthHost) {
        self.host = host
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        log(logLevel: .verbose, message: "🧨 destroyed: \(self.self)")
    }

    override func viewDidLoad() {
        view.addSubview(indicator)
        indicator.color = theme.colorTheme.disabled1
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        indicator.startAnimating()
    }

    override func viewDidAppear(_ animated: Bool) {
        viewModel.generateOAuthURL(host, with: { [weak self] result in
            switch result {
            case .failure(let error):
                _ = ErrorHandler.shared.handle(error: error)
                let alert = AlertController(title: "ERROR!", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    self?.dismiss(animated: true, completion: nil)
                }))
                alert.show()
            case .success(let urlString):
                DispatchQueue.main.async {
                    // if klarna show webview, otherwise oauth
                    if self?.host == OAuthHost.klarna {
                        self?.presentWebview(urlString)
                    } else {
                        self?.createPaymentInstrument(urlString)
                    }
                }
            }
        })
    }

    private func presentWebview(_ urlString: String) {
        let vc = WebViewController()
        vc.url = URL(string: urlString)
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    func createPaymentInstrument(_ urlString: String) {
        if #available(iOS 13, *) {
            var session: ASWebAuthenticationSession?
            
            guard let authURL = URL(string: urlString) else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "https://primer.io/",
                completionHandler: { [weak self] (url, error) in
                    if let error = error {
                        _ = ErrorHandler.shared.handle(error: error)
                    }
                    
                    if (error is PrimerError) {
                        self?.router.show(.error())
                    } else if (error.exists) {
                        self?.router.pop()
                    } else {
                        self?.onOAuthCompleted(callbackURL: url)
                    }
                }
            )
            
            session?.presentationContextProvider = self
            
            self.session = session
            
            session?.start()
        } else {
            var session: SFAuthenticationSession?
            
            guard let authURL = URL(string: urlString) else { router.show(.error()); return }
            
            session = SFAuthenticationSession(
                url: authURL,
                callbackURLScheme: viewModel.urlSchemeIdentifier,
                completionHandler: { [weak self] (url, error) in
                    error.exists ? self?.router.show(.error()) : self?.onOAuthCompleted(callbackURL: url)
                }
            )
            
            session?.start()
        }
    }

    private func onOAuthCompleted(callbackURL: URL?) {
        viewModel.tokenize(host, with: { [weak self] error in
            DispatchQueue.main.async {
                error.exists ? self?.router.show(.error()) : self?.router.show(.success(type: .regular))
            }
        })
    }
}

@available(iOS 11.0, *)
extension OAuthViewController: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 12.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }

}

@available(iOS 11.0, *)
extension OAuthViewController: ReloadDelegate {
    func reload() {
        viewModel.tokenize(host, with: { [weak self] error in
            DispatchQueue.main.async {
                error.exists ? self?.router.show(.error()) : self?.router.show(.success(type: .regular))
            }
        })
    }
}

class WebViewController: UIViewController, WKNavigationDelegate {

    @Dependency private(set) var state: AppStateProtocol

    weak var delegate: ReloadDelegate?

    let webView = WKWebView()

    var url: URL?

    override func loadView() {
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        self.view = webView
    }

    override func viewDidLoad() {
        webView.scrollView.bounces = false
        if let url = url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        delegate?.reload()
    }

    func queryValue(for name: String, of url: URL?) -> String? {
        guard let url = url,
              let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItem = urlComponents.queryItems?.last(where: {$0.name == name}) else { return nil }
        return queryItem.value
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        log(logLevel: .info, message: "🚀 \(navigationAction.request.url?.host ?? "n/a")")
        
        if let url = navigationAction.request.url, url.host == "primer.io" || url.host == "api.playground.klarna.com"{
            
            let val = queryValue(for: "token", of: url)
            
            log(logLevel: .info, message: "🚀🚀 \(url)")

            state.authorizationToken = val

            log(logLevel: .info, message: "🚀🚀🚀 \(state.authorizationToken ?? "n/a")")

            decisionHandler(.cancel)

            dismiss(animated: true, completion: nil)

            return
        }
        
        decisionHandler(.allow)
    }

}

#endif
