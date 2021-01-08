import UIKit
import PassKit
import AuthenticationServices

class DirectCheckoutViewController: UIViewController {
    
    private let indicator = UIActivityIndicatorView()
    private var subView: DirectCheckoutView?
    private let transitionDelegate = TransitionDelegate()
    
    var viewModel: DirectCheckoutViewModelProtocol
    
    init(with viewModel: DirectCheckoutViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.subView = DirectCheckoutView(frame: view.frame, theme: viewModel.theme)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.backgroundColor = viewModel.theme.backgroundColor
        addLoadingView(indicator)
        viewModel.loadCheckoutConfig({ error in
            DispatchQueue.main.async {
                
                if let error = error {
                    print("error!", error)
                } else {
                    self.removeLoadingView(self.indicator)
                    self.addSubView()
                }
            }
        })
    }
    
    private func addSubView() {
        guard let subView = self.subView else { return }
        view.addSubview(subView)
        subView.tableView.delegate = self
        subView.tableView.dataSource = self
        subView.pin(to: self.view)
        subView.title.text = viewModel.amountViewModel.toLocal()
        subView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell5")
    }
    
}

/** Adds extension to comply with table view protocol (which contains the payment method buttons).*/
extension DirectCheckoutViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.paymentMethods.count
    }
    
    // There is just one row in every section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Set the spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12.0
    }
    
    // Make the background color show through
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell5")
        
        let method = viewModel.paymentMethods[indexPath.section]
        let methodView = PaymentMethodComponent.init(frame: view.frame, method: method, theme: viewModel.theme)
    
        cell.layer.cornerRadius = 12.0
        cell.contentView.addSubview(methodView)
        methodView.pin(to: cell.contentView)
        cell.frame = cell.frame.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        cell.backgroundColor = .white
        cell.separatorInset = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vm = viewModel.paymentMethods[indexPath.section]
        
        switch vm.type {
        case .APPLE_PAY:
            let applePayViewController = ApplePayViewController(with: viewModel.applePayViewModel)
            self.present(applePayViewController, animated: true, completion: nil)
        case .GOOGLE_PAY: break
        case .PAYMENT_CARD:
            let cardFormViewController = CardFormViewController(with: viewModel.cardFormViewModel)
            self.present(cardFormViewController, animated: true, completion: nil)
        case .PAYPAL:
            let paypalVC = OAuthViewController(with: viewModel.oAuthViewModel)
            self.present(paypalVC, animated: true, completion: nil)
        }
        
    }
    
}

