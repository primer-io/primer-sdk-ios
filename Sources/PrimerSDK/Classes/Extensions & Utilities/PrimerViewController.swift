#if canImport(UIKit)

import UIKit

internal class PrimerViewController: UIViewController {
    
    override var title: String? {
        didSet {
            (parent as? PrimerContainerViewController)?.title = title
            (parent as? PrimerContainerViewController)?.mockedNavigationBar.title = title
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let tmpTitle = title
        title = tmpTitle
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let tmpTitle = title
        title = tmpTitle
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
