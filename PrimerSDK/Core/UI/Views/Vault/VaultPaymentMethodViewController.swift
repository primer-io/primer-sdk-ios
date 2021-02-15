import UIKit

class VaultPaymentMethodViewController: UIViewController {
    let transitionDelegate = TransitionDelegate()
    
    var showDeleteIcon = false
    
    
    var subView: VaultPaymentMethodView = VaultPaymentMethodView()
    @Dependency private(set) var viewModel: VaultPaymentMethodViewModelProtocol
    @Dependency private(set) var theme: PrimerThemeProtocol
    
    weak var delegate: ReloadDelegate?
    @Dependency private(set) var router: RouterDelegate
    
    deinit { print("🧨 destroy:", self.self) }
    
    override func viewDidLoad() {
        view.addSubview(subView)
        subView.delegate = self
        subView.pin(to: view)
        subView.render()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        delegate?.reload()
    }
}

extension VaultPaymentMethodViewController: VaultPaymentMethodViewDelegate {
    
    func edit() {
        showDeleteIcon = !showDeleteIcon
        subView.tableView.reloadData()
    }
    
    func cancel() {
        router.pop()
    }
    
    func showPayPal() {
        router.show(.oAuth)
    }
}
