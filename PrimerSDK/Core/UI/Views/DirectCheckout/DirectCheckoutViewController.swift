import UIKit
import PassKit
import AuthenticationServices

class DirectCheckoutViewController: UIViewController {
    
    private let indicator = UIActivityIndicatorView()
    private var subView: DirectCheckoutView?
    
    var viewModel: DirectCheckoutViewModelProtocol
    
    weak var router: RouterDelegate?
    
    init(with viewModel: DirectCheckoutViewModelProtocol, and router: RouterDelegate) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { print("🧨 destroying:", self.self) }
    
    override func viewDidLoad() {
        view.backgroundColor = viewModel.theme.backgroundColor
        addLoadingView(indicator)
        viewModel.loadCheckoutConfig({ [weak self] error in
            DispatchQueue.main.async {
                if let error = error { return print("error!", error) }
                guard let indicator = self?.indicator else { return }
                self?.removeLoadingView(indicator)
                self?.addSubView()
            }
        })
    }
    
    private func addSubView() {
        let subView = DirectCheckoutView(frame: view.frame, theme: viewModel.theme, amount: viewModel.amountViewModel.toLocal())
        subView.tableView.delegate = self
        subView.tableView.dataSource = self
        subView.delegate = self
        self.subView = subView
        view.addSubview(subView)
        subView.pin(to: view)
        subView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell5")
    }
    
}

extension DirectCheckoutViewController: DirectCheckoutViewDelegate {
    func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
}
