//
//  PrimerOAuthViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 6/8/21.
//

import Foundation

protocol PrimerOAuthViewModel {
    var host: OAuthHost { get }
    var webViewCompletion: ((_ klarnaToken: String?, _ error: Error?) -> Void)? { get }
    func presentOAuth(on viewController: UIViewController, completion: @escaping (Result<Void, Error>) -> Void)
    func createPaymentInstrument(_ url: URL)
//    func onOAuthCompleted(callbackURL: URL?)
}

extension PrimerOAuthViewModel {
    func createPaymentInstrument(_ url: URL) {
        
    }
}

class KlarnaViewModel: PrimerOAuthViewModel {
    var webViewCompletion: ((String?, Error?) -> Void)?
    
    var host: OAuthHost = .klarna
    
    init(webViewCompletion: ((String?, Error?) -> Void)?) {
        self.webViewCompletion = webViewCompletion
    }
    
    func presentOAuth(on viewController: UIViewController, completion: @escaping (Result<Void, Error>) -> Void) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
        viewModel.generateOAuthURL(.klarna, with: { [weak self] result in
            DispatchQueue.main.async {
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                
                switch result {
                case .failure(let error):
                    completion(.failure(error))
//                    _ = ErrorHandler.shared.handle(error: error)
//                    Primer.shared.delegate?.checkoutFailed?(with: error)
//
//                    if settings.hasDisabledSuccessScreen {
//                        Primer.shared.dismissPrimer()
//                    } else {
//                        let svc = ErrorViewController(message: error.localizedDescription)
//                        svc.view.translatesAutoresizingMaskIntoConstraints = false
//                        svc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
//                        Primer.shared.primerRootVC?.show(viewController: svc)
//                    }
                    
                case .success(let urlString):
                    let webViewController = WebViewController()
                    webViewController.url = URL(string: urlString)
                    webViewController.klarnaWebViewCompletion = self?.webViewCompletion
                    webViewController.modalPresentationStyle = .fullScreen
                    viewController.present(webViewController, animated: true, completion: nil)
                    completion(.success(()))
                }
            }
        })
    }
    
    func onOAuthCompleted(callbackURL: URL?) {
        
    }
}

//class PayPalViewModel: PrimerOAuthViewModel {
//    var host: OAuthHost = .paypal
//
//    func presentOAuth(on viewController: UIViewController) {
//
//    }
//
//    func createPaymentInstrument(_ url: URL) {
//
//    }
//
//    func onOAuthCompleted(callbackURL: URL?) {
//
//    }
//}

//class PrimerOAuthViewModel {
//
//}
//
//@available(iOS 11.0, *)
//extension PrimerRootViewController: ASWebAuthenticationPresentationContextProviding {
//    @available(iOS 12.0, *)
//    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
//        return self.view.window ?? ASPresentationAnchor()
//    }
//}
//
//@available(iOS 11.0, *)
//extension PrimerRootViewController: ReloadDelegate {
//    // Not used in Klarna, check PayPal
//    func reload() {
//        let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
//        viewModel.tokenize(host, with: { err in
//            DispatchQueue.main.async {
//                let router: RouterDelegate = DependencyContainer.resolve()
//
//                if let err = err {
//                    _ = ErrorHandler.shared.handle(error: err)
//                    // FIXME: I'm not feeling comfortable doing nothing with the error, showing an error screen and passing a generic error
//                    // to the developer from the Router (which has not information about it). Also, this means that the Router is taking
//                    // a decision based on a UI element (i.e. whether the vc is of type ErrorViewController).
//                    router.show(.error(error: PrimerError.generic))
//                } else {
//                    router.show(.success(type: .regular))
//                }
//            }
//        })
//    }
//}
