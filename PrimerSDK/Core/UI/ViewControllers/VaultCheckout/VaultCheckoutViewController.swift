import UIKit
import PassKit

class VaultCheckoutViewController: UIViewController {
    let vaultCheckoutView = VaultCheckoutView()
    private var viewModel: VaultCheckoutViewModelProtocol
    private let loadingIndicator = UIActivityIndicatorView()
    private let transitionDelegate = TransitionDelegate()
    
    init(_ viewModel: VaultCheckoutViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = transitionDelegate
        view.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLoadingView(loadingIndicator)
        viewModel.loadConfig({ [weak self] error in
            DispatchQueue.main.async {
                guard let indicator = self?.loadingIndicator else { return }
                self?.removeLoadingView(indicator)
                self?.addVaultCheckoutView()
            }
        })
    }
    
    private func addVaultCheckoutView() {
        view.addSubview(self.vaultCheckoutView)
        vaultCheckoutView.setTableViewDelegates(self)
        vaultCheckoutView.payButton.setTitle("Pay", for: .normal)
        vaultCheckoutView.payButton.addTarget(self, action: #selector(completePayment), for: .touchUpInside)
        vaultCheckoutView.applePayButton.addTarget(self, action: #selector(showApplePay), for: .touchUpInside)
        vaultCheckoutView.pin(to: view)
    }
    
    @objc private func completePayment() {
        vaultCheckoutView.payButton.showSpinner()
        viewModel.authorizePayment({ error in
            DispatchQueue.main.async { self.showModal(error) }
        })
    }
    
    @objc private func showApplePay() {
        let applePayDelegate = viewModel.applePayViewModel
        let applePayVC = ApplePayViewController(with: applePayDelegate)
        self.present(applePayVC, animated: true, completion: nil)
    }
}

extension VaultCheckoutViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell3")
            cell.textLabel?.text = "John Doe"
            cell.detailTextLabel?.text = "1 Infinite Loop Cupertino, CA 95014, USA"
            cell.accessoryType = .disclosureIndicator
            cell.separatorInset = UIEdgeInsets.zero
            cell.backgroundColor = .white
            cell.tintColor = .black
            cell.textLabel?.textColor = .darkGray
            return cell
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "cell3")
            
            let selectedCard = viewModel.paymentMethods.first(where: { vm in
                return vm.id == viewModel.selectedPaymentMethodId
            })
            
            if (selectedCard != nil) {
                cell.textLabel?.text = "**** **** **** \(selectedCard!.last4)"
            } else {
                cell.textLabel?.text = "select a card"
            }
            
            cell.accessoryType = .disclosureIndicator
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
            cell.backgroundColor = .white
            cell.tintColor = .black
            cell.textLabel?.textColor = .darkGray
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath.row == 0) {
            
        } else {
            let paymentMethodVCDelegate = viewModel.vaultPaymentMethodViewModel
            let paymentMethodVC = VaultPaymentMethodViewController(paymentMethodVCDelegate)
            paymentMethodVC.delegate = self
            self.present(paymentMethodVC, animated: true, completion: nil)
        }
    }
}
