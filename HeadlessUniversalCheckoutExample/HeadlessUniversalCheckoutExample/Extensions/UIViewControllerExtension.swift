//
//  UIViewControllerExtension.swift
//  HeadlessUniversalCheckoutExample
//
//  Created by Evangelos on 16/2/22.
//

import UIKit

public class MyViewController: UIViewController {
    var activityIndicatorView: UIActivityIndicatorView?
}

extension MyViewController {
    func showError(withMessage message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }

    func showLoading() {
        DispatchQueue.main.async {
            if self.activityIndicatorView == nil {
                self.activityIndicatorView = UIActivityIndicatorView()
            }
            self.view.addSubview(self.activityIndicatorView!)
            self.activityIndicatorView!.translatesAutoresizingMaskIntoConstraints = false
            self.activityIndicatorView!.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.activityIndicatorView!.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.activityIndicatorView!.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            self.activityIndicatorView!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            self.activityIndicatorView!.backgroundColor = .lightGray.withAlphaComponent(0.3)
            self.activityIndicatorView!.color = .darkGray
            self.activityIndicatorView!.startAnimating()
        }
    }
    
    func stopLoading() {
        DispatchQueue.main.async {
            self.activityIndicatorView?.stopAnimating()
            self.activityIndicatorView?.removeFromSuperview()
            self.activityIndicatorView = nil
        }
    }
}
