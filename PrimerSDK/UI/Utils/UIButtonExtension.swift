import UIKit

extension UIButton {
    func showSpinner(_ color: UIColor = .white) {
        self.isUserInteractionEnabled = false
        self.setTitle("", for: .normal)
        let newSpinner = UIActivityIndicatorView()
        newSpinner.color = color
        self.addSubview(newSpinner)
        newSpinner.translatesAutoresizingMaskIntoConstraints = false
        newSpinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        newSpinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        newSpinner.widthAnchor.constraint(equalToConstant: 20).isActive = true
        newSpinner.heightAnchor.constraint(equalToConstant: 20).isActive = true
        newSpinner.startAnimating()
    }
    
    func hideSpinner(_ title: String, spinner: UIActivityIndicatorView) {
        spinner.removeFromSuperview()
        self.setTitle(title, for: .normal)
    }
}
