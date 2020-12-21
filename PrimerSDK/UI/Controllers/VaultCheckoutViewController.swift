import UIKit
import PassKit

protocol VaultCheckoutViewControllerDelegate {
    var paymentMethods: [VaultedPaymentMethodViewModel] { get }
    var selectedPaymentMethodId: String { get }
    func loadConfig(_ completion: @escaping (Error?) -> Void)
    func showPaymentMethodView(_ controller: UIViewController)
    func showApplePayView(_ controller: UIViewController)
    func authorizePayment(_ completion: @escaping (Error?) -> Void)
}

class VaultCheckoutViewController: UIViewController {
    private let vaultCheckoutView = VaultCheckoutView()
    private var delegate: VaultCheckoutViewControllerDelegate
    private let loadingIndicator = UIActivityIndicatorView()
    private let transitionDelegate = TransitionDelegate()
    
    init(_ delegate: VaultCheckoutViewControllerDelegate) {
        self.delegate = delegate
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
        delegate.loadConfig({ error in
            DispatchQueue.main.async {
                self.removeLoadingView(self.loadingIndicator)
                self.addVaultCheckoutView()
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
        delegate.authorizePayment({ error in
            DispatchQueue.main.async { self.showModal(error) }
        })
    }
    
    @objc private func showApplePay() {
        delegate.showApplePayView(self)
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
            
            let selectedCard = delegate.paymentMethods.first(where: { vm in
                return vm.id == delegate.selectedPaymentMethodId
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
            delegate.showPaymentMethodView(self)
        }
    }
}
