#if canImport(UIKit)

import UIKit

internal class PrimerViewController: UIViewController {
    
    var titleImage: UIImage?
    var titleImageTintColor: UIColor?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(PrimerViewController.dismissKeyboard))
//        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func removeLoadingView(_ indicator: UIActivityIndicatorView) {
        indicator.removeFromSuperview()
    }
    
    func addLoadingView(_ indicator: UIActivityIndicatorView) {
        view.addSubview(indicator)
        
    }
}

extension PrimerViewController {
    
    func dismissOrShowResultScreen(_ error: Error? = nil) {
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if settings.hasDisabledSuccessScreen {
            Primer.shared.dismiss()
        } else {
            let status: PrimerResultViewController.ScreenType = error == nil ? .success : .failure
            let resultViewController = PrimerResultViewController(screenType: status, message: error?.localizedDescription)
            resultViewController.view.translatesAutoresizingMaskIntoConstraints = false
            resultViewController.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
            Primer.shared.primerRootVC?.show(viewController: resultViewController)
        }
    }
}

#endif
