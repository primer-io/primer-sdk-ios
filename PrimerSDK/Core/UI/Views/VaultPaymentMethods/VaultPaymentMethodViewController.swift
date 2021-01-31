import UIKit

class VaultPaymentMethodViewController: UIViewController {
    let transitionDelegate = TransitionDelegate()
    
    var showDeleteIcon = false
    
    
    var subView: VaultPaymentMethodView = VaultPaymentMethodView()
    var viewModel: VaultPaymentMethodViewModelProtocol
    
    weak var delegate: ReloadDelegate?
    weak var router: RouterDelegate?
    
    init(_ viewModel: VaultPaymentMethodViewModelProtocol, router: RouterDelegate?) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
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
    var theme: PrimerTheme {
        return viewModel.theme
    }
    
    func edit() {
        showDeleteIcon = !showDeleteIcon
        subView.tableView.reloadData()
    }
    
    func cancel() {
        router?.pop()
    }
    
    func showPayPal() {
        router?.show(.oAuth)
    }
}
