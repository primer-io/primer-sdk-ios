//
//  PrimerLoadWebViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 04/08/2021.
//
#if canImport(UIKit)

import UIKit

class PrimerLoadWebViewController: PrimerViewController, ReloadDelegate {
    let indicator = UIActivityIndicatorView()

    weak var viewModel: PrimerLoadWebViewModelProtocol?

    init(with viewModel: PrimerLoadWebViewModelProtocol) {
        self.viewModel = viewModel
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
        presentLoader()
        generateUrl()
    }

    internal func presentLoader() {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        if !settings.isInitialLoadingHidden {
            addLoadingView(indicator)
        }
    }

    internal func generateUrl() {
        viewModel?.generateWebViewUrl { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    break // we're gonna refactor this method once merged in with the all the UI updates.
                case .success(let urlString):
                    if let webViewModel = self?.viewModel?.getWebViewModel() {
                        let webViewController = PrimerWebViewController(with: webViewModel)
                        self?.presentWebview(urlString, webViewController: webViewController)
                    }
                }
            }
        }
    }

//    internal func presentError(_ error: Error) {
//        _ = ErrorHandler.shared.handle(error: error)
//        Primer.shared.delegate?.checkoutFailed?(with: error)
//        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
//        let router: RouterDelegate = DependencyContainer.resolve()
//        if settings.hasDisabledSuccessScreen {
//            let rootViewController = router.root
//            UIView.animate(withDuration: 0.3) {
//                let presenter = rootViewController?.presentationController as? PresentationController
//                presenter?.blurEffectView.alpha = 0.0
//            } completion: { (_) in
//                rootViewController?.dismiss(animated: true, completion: nil)
//            }
//        } else {
//            router.show(.error(error: error))
//        }
//    }

    internal func presentWebview(_ urlString: String, webViewController: PrimerWebViewController) {
        presentBlurEffect()
        webViewController.url = URL(string: urlString)
        webViewController.delegate = self
        present(webViewController, animated: true, completion: nil)
    }
    // can probably put this in superclass
    private func presentBlurEffect() {
        let routerDelegate: RouterDelegate = DependencyContainer.resolve()
        let router = routerDelegate as! Router
        let rootViewController = router.root
        UIView.animate(withDuration: 0.3) {
            let presenter = rootViewController?.presentationController as? PresentationController
            presenter?.blurEffectView.alpha = 0.7
        }
    }

    func reload() {
        viewModel?.tokenize()
    }
}

#endif
