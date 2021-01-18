import UIKit
import PassKit

class VaultCheckoutViewController: UIViewController {
    
    var vaultCheckoutView: VaultCheckoutView?
    
    private var viewModel: VaultCheckoutViewModelProtocol
    private let loadingIndicator = UIActivityIndicatorView()
    private let transitionDelegate = TransitionDelegate()
    
    weak var router: RouterDelegate?
    
    init(_ viewModel: VaultCheckoutViewModelProtocol, router: RouterDelegate?) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { print("🧨 destroy:", self.self) }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.vaultCheckoutView = VaultCheckoutView(frame: view.frame, theme: viewModel.theme, delegate: self)
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
        guard let vaultCheckoutView = self.vaultCheckoutView else { return }
        view.addSubview(vaultCheckoutView)
        vaultCheckoutView.setTableViewDelegates(self)
        vaultCheckoutView.pin(to: view)
    }
}

extension VaultCheckoutViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell3")
        
        let selectedCard = viewModel.paymentMethods.first(where: { paymentMethod in
            return paymentMethod.token == viewModel.selectedPaymentMethodId
        })
        
        if (selectedCard != nil) {
            cell.textLabel?.text = selectedCard?.description
        } else {
            cell.textLabel?.text = "select a card".localized()
        }
        cell.accessoryType = .disclosureIndicator
        cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
        cell.backgroundColor = .white
        cell.tintColor = .black
        cell.textLabel?.textColor = .darkGray
        return cell
        //        if (indexPath.row == 0) {
        //            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell3")
        //            cell.textLabel?.text = "John Doe"
        //            cell.detailTextLabel?.text = "1 Infinite Loop Cupertino, CA 95014, USA"
        //            cell.accessoryType = .disclosureIndicator
        //            cell.separatorInset = UIEdgeInsets.zero
        //            cell.backgroundColor = .white
        //            cell.tintColor = .black
        //            cell.textLabel?.textColor = .darkGray
        //            return cell
        //        } else {
        //            let cell = UITableViewCell(style: .default, reuseIdentifier: "cell3")
        //
        //            let selectedCard = viewModel.paymentMethods.first(where: { vm in
        //                return vm.id == viewModel.selectedPaymentMethodId
        //            })
        //
        //            if (selectedCard != nil) {
        //                cell.textLabel?.text = "**** **** **** \(selectedCard!.last4)"
        //            } else {
        //                cell.textLabel?.text = "select a card".localized()
        //            }
        //            cell.accessoryType = .disclosureIndicator
        //            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
        //            cell.backgroundColor = .white
        //            cell.tintColor = .black
        //            cell.textLabel?.textColor = .darkGray
        //            return cell
        //        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        router?.show(.vaultPaymentMethods(delegate: self))
    }
}

extension VaultCheckoutViewController: VaultCheckoutViewDelegate {
    func cancel() {
        router?.pop()
    }
    
    func pay() {
        guard let vaultCheckoutView = self.vaultCheckoutView else { return }
        vaultCheckoutView.payButton.showSpinner()
        
        viewModel.authorizePayment({ [weak self] error in
            DispatchQueue.main.async {
                if (error.exists) {
                    self?.router?.show(.error)
                    return
                }
                self?.router?.show(.success)
            }
        })
    }
}
