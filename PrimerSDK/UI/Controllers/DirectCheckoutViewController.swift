import UIKit
import PassKit
import AuthenticationServices

struct PaymentMethodViewModel {
    func toString() -> String {
        switch type {
        case .PAYMENT_CARD: return "Pay by card"
        case .APPLE_PAY: return "Pay by card"
        case .PAYPAL: return "PayPal"
        default: return ""
        }
    }
    let type: ConfigPaymentMethodType
    var presentTokenizingViewController: (_ controller: UIViewController) -> Void
}

struct AmountViewModel {
    let amount: Int
    let currency: Currency
    var formattedAmount: String {
        return String(format: "%.2f", (Double(amount) / 100))
    }
    func toLocal() -> String {
        switch currency {
        case .USD:
            return "$\(formattedAmount)"
        case .GBP:
            return "£\(formattedAmount)"
        case .EUR:
            return "€\(formattedAmount)"
        case .JPY:
            return "¥\(amount)"
        case .SEK:
            return "\(amount) SEK"
        case .NOK:
            return "$\(amount) NOK"
        case .DKK:
            return "$\(amount) DKK"
        default:
            return "\(amount)"
        }
    }
}

protocol DirectCheckoutViewControllerDelegate {
    var amountViewModel: AmountViewModel { get }
    var viewModels: [PaymentMethodViewModel]? { get }
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) -> Void
}

class DirectCheckoutViewController: UIViewController {
    
    private let indicator = UIActivityIndicatorView()
    private let subView = DirectCheckoutView()
    private let transitionDelegate = TransitionDelegate()
    
    var delegate: DirectCheckoutViewControllerDelegate
    
    
    
    init(_ delegate: DirectCheckoutViewControllerDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        addLoadingView(indicator)
        delegate.loadCheckoutConfig({ error in
            DispatchQueue.main.async {
                self.removeLoadingView(self.indicator)
                self.addSubView()
            }
        })
    }
    
    private func addSubView() {
        view.addSubview(subView)
        subView.pin(to: self.view)
        subView.title.text = delegate.amountViewModel.toLocal()
        self.subView.setTableViewDelegates(self)
        subView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell5")
    }
    
}

/** Adds extension to comply with table view protocol (which contains the payment method buttons).*/
extension DirectCheckoutViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return delegate.viewModels?.count ?? 0
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
        
        if let title = delegate.viewModels?[indexPath.section].toString() {
            
            let label = UILabel()
            label.textAlignment = .center
            label.text = title
            //            label.textColor = .red
            //            label.backgroundColor = .cyan
            cell.layer.cornerRadius = 12.0
            cell.contentView.addSubview(label)
            
            label.pin(to: cell.contentView)
            
        }
        
        cell.frame = cell.frame.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        cell.backgroundColor = .white
        cell.separatorInset = UIEdgeInsets.zero
        //        cell.backgroundColor = .white
        //        cell.textLabel?.textColor = .darkGray
        
        
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate.viewModels?[indexPath.section].presentTokenizingViewController(self)
    }
    
}

