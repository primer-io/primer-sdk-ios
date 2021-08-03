#if canImport(UIKit)

import UIKit

internal class PrimerViewController: UIViewController {
    
    override var title: String? {
        didSet {
            (parent as? PrimerContainerViewController)?.title = title
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

    func addLoadingView(_ indicator: UIActivityIndicatorView) {
        indicator.color = .black
        view.addSubview(indicator)
        
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        indicator.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        indicator.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        indicator.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        indicator.startAnimating()
    }

    private func setLoadingIndicatorConstraints(_ indicator: UIActivityIndicatorView) {
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        indicator.widthAnchor.constraint(equalToConstant: 20).isActive = true
        indicator.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }

    func removeLoadingView(_ indicator: UIActivityIndicatorView) {
        indicator.removeFromSuperview()
    }

    func remove() {
        // Just to be safe, we check that this view controller
        // is actually added to a parent before removing it.
        guard parent != nil else {
            return
        }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

}

#endif
