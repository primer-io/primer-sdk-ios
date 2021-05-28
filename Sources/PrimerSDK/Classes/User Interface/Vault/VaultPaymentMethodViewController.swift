#if canImport(UIKit)

import UIKit

internal class VaultPaymentMethodViewController: PrimerViewController {
    weak var transitionDelegate = TransitionDelegate()

    var showDeleteIcon = false

    var subView: VaultPaymentMethodView = VaultPaymentMethodView()

    weak var delegate: ReloadDelegate?

    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
    }

    override func viewDidLoad() {
        view.addSubview(subView)
        subView.delegate = self
        subView.pin(to: view)
        subView.render()
    }

    override func viewWillDisappear(_ animated: Bool) {
        delegate?.reload()
    }
}

extension VaultPaymentMethodViewController: VaultPaymentMethodViewDelegate {

    func edit() {
        showDeleteIcon = !showDeleteIcon
        subView.tableView.reloadData()
    }

    func cancel() {
        let router: RouterDelegate = DependencyContainer.resolve()
        router.pop()
    }

    func showPayPal() {
        let router: RouterDelegate = DependencyContainer.resolve()
        router.show(.oAuth(host: .paypal))
    }
}

#endif
