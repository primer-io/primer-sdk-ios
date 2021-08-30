#if canImport(UIKit)

import UIKit

internal class PrimerViewController: UIViewController {
    
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

}

#endif
