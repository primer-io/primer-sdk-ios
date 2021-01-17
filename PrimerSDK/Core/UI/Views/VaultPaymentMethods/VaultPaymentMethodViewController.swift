import UIKit

class VaultPaymentMethodViewController: UIViewController {
    let transitionDelegate = TransitionDelegate()
    var showDeleteIcon = false
    var subView: VaultPaymentMethodView?
    var viewModel: VaultPaymentMethodViewModelProtocol
    var delegate: ReloadDelegate?
    
    weak var router: RouterDelegate?
    
    init(_ viewModel: VaultPaymentMethodViewModelProtocol, router: RouterDelegate?) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = viewModel.theme.backgroundColor
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { print("🧨 destroy:", self.self) }
    
    override func viewDidLoad() {
        subView = VaultPaymentMethodView(frame: view.frame, delegate: self, dataSource: self, theme: viewModel.theme)
        subView?.delegate = self
        guard let subView = self.subView else { return }
        view.addSubview(subView)
        subView.pin(to: view)
        subView.addButton.addTarget(self, action: #selector(addPaymentMethod), for: .touchUpInside)
        // You must register the cell with a reuse identifier
        subView.tableView.register(PaymentMethodTableViewCell.self, forCellReuseIdentifier: "paymentMethodCell")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        delegate?.reload()
    }
    
    @objc private func addPaymentMethod() {
//        let cardFormVCDelegate = viewModel.cardFormViewModel
//        let vc = CardFormViewController(with: cardFormVCDelegate, )
//        vc.delegate = self
//        self.present(vc, animated: true, completion: nil)
    }
    
}

extension VaultPaymentMethodViewController: VaultPaymentMethodViewDelegate {
    func edit() {
        showDeleteIcon = !showDeleteIcon
        subView?.tableView.reloadData()
    }
    func cancel() {
        router?.pop()
    }
    func showCardForm() {
        router?.show(.cardForm)
    }
    func showPayPal() {
        router?.show(.oAuth)
    }
}
