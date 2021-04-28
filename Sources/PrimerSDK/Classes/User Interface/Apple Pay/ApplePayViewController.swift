#if canImport(UIKit)

import UIKit

class ApplePayViewController: UIViewController {
    private let indicator = UIActivityIndicatorView()

    weak var transitionDelegate = TransitionDelegate()

    init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        log(logLevel: .verbose, title: nil, message: "\(self.self) deinit", prefix: "🧨", suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
    }

    override func viewDidLoad() {
        addLoadingView(indicator)
    }

    override func viewDidAppear(_ animated: Bool) {
        onApplePayButtonPressed()
    }

    func displayDefaultAlert(title: String?, message: String?) {
        let alert = AlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        alert.show()
    }

}

#endif
