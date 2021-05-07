#if canImport(UIKit)

import UIKit
import AuthenticationServices
import SafariServices
import WebKit

@available(iOS 11.0, *)
class OAuthViewController: UIViewController {

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
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        indicator.color = theme.colorTheme.disabled1
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        indicator.startAnimating()
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        if settings.isInitialLoadingHidden {
            indicator.isHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
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
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        let routerDelegate: RouterDelegate = DependencyContainer.resolve()
        let router = routerDelegate as! Router
        let rootViewController = router.root
        
        UIView.animate(withDuration: 0.3) {
            (rootViewController?.presentationController as? PresentationController)?.blurEffectView.alpha = 0.7
        }
        
        let webViewController = WebViewController()
        webViewController.url = URL(string: urlString)
        webViewController.delegate = self
        webViewController.klarnaWebViewCompletion = { [weak self] (urlStr, err) in
            
        }
        present(webViewController, animated: true, completion: nil)
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
                    
                    let router: RouterDelegate = DependencyContainer.resolve()

                    if (error is PrimerError) {
                        router.show(.error(error: error!))
                    } else if (error.exists) {
                        router.pop()
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

            guard let authURL = URL(string: urlString) else {
                let router: RouterDelegate = DependencyContainer.resolve()
                router.show(.error(error: PrimerError.generic))
                return
            }

            let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
            session = SFAuthenticationSession(
                url: authURL,
                callbackURLScheme: viewModel.urlSchemeIdentifier,
                completionHandler: { [weak self] (url, error) in
                    let router: RouterDelegate = DependencyContainer.resolve()
                    error.exists ? router.show(.error(error: PrimerError.generic)) : self?.onOAuthCompleted(callbackURL: url)
                }
            )

            session?.start()
        }
    }

    private func onOAuthCompleted(callbackURL: URL?) {
        let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
        
        viewModel.tokenize(host, with: { [weak self] error in
            DispatchQueue.main.async {
                let router: RouterDelegate = DependencyContainer.resolve()
                error.exists ? router.show(.error(error: PrimerError.generic)) : router.show(.success(type: .regular))
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
        let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
        viewModel.tokenize(host, with: { [weak self] error in
            DispatchQueue.main.async {
                let router: RouterDelegate = DependencyContainer.resolve()
                error.exists ? router.show(.error(error: PrimerError.generic)) : router.show(.success(type: .regular))
            }
        })
    }
}

class WebViewController: UIViewController, WKNavigationDelegate {

    weak var delegate: ReloadDelegate?

    let webView = WKWebView()

    var url: URL?
    var klarnaWebViewCompletion: ((String?, Error?) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        self.view = webView
        
        if let url = url {
            let state: AppStateProtocol = DependencyContainer.resolve()

            let clientToken = state.decodedClientToken!
            
            var request = URLRequest(url: url)
            request.allHTTPHeaderFields = [
                "Content-Type": "application/json",
                "Primer-SDK-Version": "1.0.0-beta.0",
                "Primer-SDK-Client": "IOS_NATIVE"
            ]
            webView.load(request)
        }
    }

//    override func viewWillDisappear(_ animated: Bool) {
//        delegate?.reload()
//    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        log(logLevel: .info, message: "🚀 \(navigationAction.request.url?.host ?? "n/a")")
        
        let allowedHosts: [String] = [
            "primer.io",
//            "api.playground.klarna.com",
//            "api.sandbox.primer.io"
        ]

        if let url = navigationAction.request.url, let host = url.host, allowedHosts.contains(host) {

            let val = url.queryParameterValue(for: "token")

            log(logLevel: .info, message: "🚀🚀 \(url)")
            log(logLevel: .info, message: "🚀🚀 token \(val)")
            
            let state: AppStateProtocol = DependencyContainer.resolve()

            state.authorizationToken = val
            klarnaWebViewCompletion?(val, nil)

            log(logLevel: .info, message: "🚀🚀🚀 \(state.authorizationToken ?? "n/a")")

            decisionHandler(.cancel)

            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            let routerDelegate: RouterDelegate = DependencyContainer.resolve()
            let router = routerDelegate as! Router
            let rootViewController = router.root
            
            if settings.hasDisabledSuccessScreen == false && settings.isInitialLoadingHidden == true {
                let theme: PrimerThemeProtocol = DependencyContainer.resolve()
                rootViewController?.mainView.backgroundColor = theme.colorTheme.main1
                if #available(iOS 11.0, *) {
                    (rootViewController?.children.first as? OAuthViewController)?.indicator.isHidden = false
                }
                
            } else if settings.hasDisabledSuccessScreen && settings.isInitialLoadingHidden {
                UIView.animate(withDuration: 0.3) {
                    (rootViewController?.presentationController as? PresentationController)?.blurEffectView.alpha = 0.0
                }
            }
            
            dismiss(animated: true, completion: nil)

            return
        }

        decisionHandler(.allow)
    }
    
}

#endif
