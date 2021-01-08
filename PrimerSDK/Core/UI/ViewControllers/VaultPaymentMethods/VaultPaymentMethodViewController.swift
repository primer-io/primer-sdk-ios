import UIKit

class VaultPaymentMethodViewController: UIViewController {
    let transitionDelegate = TransitionDelegate()
    var showDeleteIcon = false
    var subView: VaultPaymentMethodView?
    var viewModel: VaultPaymentMethodViewModelProtocol
    var delegate: ReloadDelegate?
    
    init(_ viewModel: VaultPaymentMethodViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = transitionDelegate
        view.backgroundColor = viewModel.theme.backgroundColor
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        subView = VaultPaymentMethodView(frame: view.frame, delegate: self, dataSource: self, theme: viewModel.theme)
        guard let subView = self.subView else { return }
        view.addSubview(subView)
        subView.pin(to: view)
        subView.backButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        subView.editButton.addTarget(self, action: #selector(editPaymentMethods), for: .touchUpInside)
        subView.addButton.addTarget(self, action: #selector(addPaymentMethod), for: .touchUpInside)
        // You must register the cell with a reuse identifier
        subView.tableView.register(PaymentMethodTableViewCell.self, forCellReuseIdentifier: "paymentMethodCell")
    }
    override func viewWillDisappear(_ animated: Bool) {
        delegate?.reload()
    }
    
    @objc private func dismissView() { dismiss(animated: true, completion: nil) }
    @objc private func editPaymentMethods() {
        showDeleteIcon = !showDeleteIcon
        subView?.tableView.reloadData()
    }
    @objc private func addPaymentMethod() {
        let cardFormVCDelegate = viewModel.cardFormViewModel
        let vc = CardFormViewController(with: cardFormVCDelegate)
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
}
