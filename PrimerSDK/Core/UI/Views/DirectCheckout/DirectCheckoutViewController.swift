import UIKit
import PassKit
import AuthenticationServices

class DirectCheckoutViewController: UIViewController {
    
    private let indicator = UIActivityIndicatorView()
    private var subView: DirectCheckoutView?
    
    @Dependency private(set) var viewModel: DirectCheckoutViewModelProtocol
    @Dependency private(set) var  router: RouterDelegate
    
    deinit { print("🧨 destroying:", self.self) }
    
    override func viewDidLoad() {
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
        let subView = DirectCheckoutView(frame: view.frame, amount: viewModel.amountViewModel.toLocal())
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
