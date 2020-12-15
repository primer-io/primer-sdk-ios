import UIKit

class SpinnerView: UIView {
    
    var spinner = UIActivityIndicatorView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        showSpinner()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showSpinner() {
        self.addSubview(spinner)
        spinner.color = .black
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        spinner.widthAnchor.constraint(equalToConstant: 20).isActive = true
        spinner.heightAnchor.constraint(equalToConstant: 20).isActive = true
        spinner.startAnimating()
    }
    
    func hideSpinner() {
        spinner.removeFromSuperview()
    }
    
}
