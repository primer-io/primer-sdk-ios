import UIKit
import PassKit

class VaultCheckoutViewController: UIViewController {
    
    var subView: VaultCheckoutView = VaultCheckoutView()
    var tokenSelectedForPayment: PaymentMethodToken?
    
    @Dependency private(set) var viewModel: VaultCheckoutViewModelProtocol
    @Dependency private(set) var router: RouterDelegate
    @Dependency private(set) var theme: PrimerThemeProtocol
    
    private let loadingIndicator = UIActivityIndicatorView()
    private let transitionDelegate = TransitionDelegate()
    
    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(subView)
        subView.delegate = self
        subView.dataSource = self
        subView.pin(to: view)
        subView.render(isBusy: true)
        viewModel.loadConfig({ [weak self] error in
            DispatchQueue.main.async {
                guard let indicator = self?.loadingIndicator else { return }
                self?.removeLoadingView(indicator)
                self?.subView.render()
            }
        })
    }
}

extension VaultCheckoutViewController: VaultCheckoutViewDataSource {
    var selectedSavedPaymentMethod: PaymentMethodToken? {
        return viewModel.paymentMethods.first(where: { paymentMethod in
            return paymentMethod.token == viewModel.selectedPaymentMethodId
        })
    }
    
    var amount: String? {
        return viewModel.amountStringed
    }
}

// MARK: UITableView
extension VaultCheckoutViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.availablePaymentOptions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Set the spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 14.0
    }
    
    // Make the background color show through
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear //transparent
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell5")
        
        let option = viewModel.availablePaymentOptions[indexPath.section]
        let methodView = PaymentMethodComponent(frame: view.frame, method: option)
    
        cell.layer.cornerRadius = 12.0
        cell.contentView.addSubview(methodView)
        methodView.pin(to: cell.contentView)
        cell.frame = cell.frame.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        cell.backgroundColor = theme.colorTheme.main1
        cell.separatorInset = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let option = viewModel.availablePaymentOptions[indexPath.section]
        
        switch option.type {
        case .APPLE_PAY: router.show(.applePay)
        case .GOOGLE_PAY: break
        case .PAYMENT_CARD: router.show(.form(type: .cardForm(theme: theme)))
        case .PAYPAL: router.show(.oAuth(host: .paypal))
        case .GOCARDLESS_MANDATE: router.show(.form(type: .iban(mandate: viewModel.mandate, popOnComplete: false)))
        case .KLARNA: router.show(.oAuth(host: .klarna))
        }
    }
}

// MARK: VaultCheckoutViewDelegate
extension VaultCheckoutViewController: VaultCheckoutViewDelegate {
    func openVault() {
        router.show(.vaultPaymentMethods(delegate: self))
    }
    
    func cancel() {
        router.pop()
    }
    
    func selectTokenForPayment(token: PaymentMethodToken) {
        tokenSelectedForPayment = token
    }
    
    func pay() {
        viewModel.authorizePayment({ [weak self] error in
            DispatchQueue.main.async {
                if (error.exists) {
                    self?.router.show(.error())
                    return
                }
                self?.router.show(.success(type: .regular))
            }
        })
    }
}
