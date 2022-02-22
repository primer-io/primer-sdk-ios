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

#endif
