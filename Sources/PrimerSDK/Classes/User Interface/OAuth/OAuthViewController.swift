#if canImport(UIKit)

import UIKit
import AuthenticationServices
import SafariServices

@available(iOS 11.0, *)
internal class OAuthViewController: PrimerViewController {

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
        super.viewDidLoad()
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        if !settings.isInitialLoadingHidden {
            view.addSubview(indicator)
            indicator.color = theme.colorTheme.disabled1
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            indicator.startAnimating()
        }
        
        let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
        viewModel.generateOAuthURL(host, with: { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    _ = ErrorHandler.shared.handle(error: error)
                    Primer.shared.delegate?.checkoutFailed(with: error)
                    
                    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                    
                    let routerDelegate: RouterDelegate = DependencyContainer.resolve()
                    
                    let router = routerDelegate as! Router
                    
                    if settings.hasDisabledSuccessScreen {
                        
                        let rootViewController = router.root
                        
                        UIView.animate(withDuration: 0.3) {
                            (rootViewController?.presentationController as? PresentationController)?.blurEffectView.alpha = 0.0
                        } completion: { (_) in
                            rootViewController?.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        router.show(.error(error: error))
                    }
                    
                case .success(let urlString):
                    // if Klarna show WebView, otherwise OAuth
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
        let routerDelegate: RouterDelegate = DependencyContainer.resolve()
        let router = routerDelegate as! Router
        let rootViewController = router.root

        UIView.animate(withDuration: 0.3) {
            (rootViewController?.presentationController as? PresentationController)?.blurEffectView.alpha = 0.7
        }
        
        let webViewController = WebViewController()
        webViewController.url = URL(string: urlString)
        webViewController.delegate = self
        webViewController.klarnaWebViewCompletion = { [weak self] (_, err) in
//            let err: Error?  = KlarnaException.noCoreUrl
            if let err = err {
                _ = ErrorHandler.shared.handle(error: err)
                router.show(.error(error: err))
                
            } else {
                guard let host = self?.host else {
                    let error = PrimerError.failedToLoadSession
                    router.show(.error(error: error))
                    return
                }
                
                let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
                viewModel.tokenize(host, with: { err in
                    DispatchQueue.main.async {
                        if let err = err {
                            _ = ErrorHandler.shared.handle(error: err)
                            router.show(.error(error: PrimerError.generic))
                        } else {
                            router.show(.success(type: .regular))
                        }
                    }
                })
            }
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            if settings.hasDisabledSuccessScreen == false && settings.isInitialLoadingHidden == true {
                let theme: PrimerThemeProtocol = DependencyContainer.resolve()
                rootViewController?.mainView.backgroundColor = theme.colorTheme.main1
                (rootViewController?.children.first as? OAuthViewController)?.indicator.isHidden = false

            } else if settings.hasDisabledSuccessScreen && settings.isInitialLoadingHidden {
                UIView.animate(withDuration: 0.3) {
                    (rootViewController?.presentationController as? PresentationController)?.blurEffectView.alpha = 0.0
                } completion: { (_) in
                    rootViewController?.dismiss(animated: true, completion: nil)
                }
            }
            
            self?.dismiss(animated: true, completion: nil)
        }
        present(webViewController, animated: true, completion: nil)
    }

    // PayPal
    func createPaymentInstrument(_ urlString: String) {
        if #available(iOS 13, *) {
            var session: ASWebAuthenticationSession?

            guard let authURL = URL(string: urlString) else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            guard let urlScheme = settings.urlScheme else {
                let router: RouterDelegate = DependencyContainer.resolve()
                router.show(.error(error: PrimerError.generic))
                return
            }

            session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: urlScheme,
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
                completionHandler: { [weak self] (url, err) in
                    if let err = err {
                        let router: RouterDelegate = DependencyContainer.resolve()
                        router.show(.error(error: PrimerError.generic))
                    } else {
                        self?.onOAuthCompleted(callbackURL: url)
                    }
                }
            )

            session?.start()
        }
    }

    // PayPal
    private func onOAuthCompleted(callbackURL: URL?) {
        let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
        
        viewModel.tokenize(host, with: { err in
            // FIXME: Is switching to the main thread really needed here? If it's needed by the Router that's handling
            // various UI procedeures, shouldn't it be moved in there?
            DispatchQueue.main.async {
                let router: RouterDelegate = DependencyContainer.resolve()
                
                if let err = err {
                    router.show(.error(error: PrimerError.generic))
                } else {
                    router.show(.success(type: .regular))
                }
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
    // Not used in Klarna, check PayPal
    func reload() {
        let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
        viewModel.tokenize(host, with: { err in
            DispatchQueue.main.async {
                let router: RouterDelegate = DependencyContainer.resolve()
                
                if let err = err {
                    _ = ErrorHandler.shared.handle(error: err)
                    // FIXME: I'm not feeling comfortable doing nothing with the error, showing an error screen and passing a generic error
                    // to the developer from the Router (which has not information about it). Also, this means that the Router is taking
                    // a decision based on a UI element (i.e. whether the vc is of type ErrorViewController).
                    router.show(.error(error: PrimerError.generic))
                } else {
                    router.show(.success(type: .regular))
                }
            }
        })
    }
}

#endif
