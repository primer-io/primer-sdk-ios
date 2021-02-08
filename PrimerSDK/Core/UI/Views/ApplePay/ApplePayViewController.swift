import UIKit

class ApplePayViewController: UIViewController {
    private let indicator = UIActivityIndicatorView()
    
    @Dependency private(set) var viewModel: ApplePayViewModelProtocol
    let transitionDelegate = TransitionDelegate()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { print("🧨 destroying:", self.self) }
    
    override func viewDidLoad() {
        addLoadingView(indicator)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        onApplePayButtonPressed()
    }
    
    func displayDefaultAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
}
