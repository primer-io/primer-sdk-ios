//
//  ConfirmMandateViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 10/01/2021.
//

import UIKit

class ConfirmMandateViewController: UIViewController {
    
    var subView: ConfirmMandateView = ConfirmMandateView()
    private var viewModel: ConfirmMandateViewModelProtocol
    weak var router: RouterDelegate?
    
    let formTypes: [ConfirmMandateFormType] = [.name, .email, .address, .iban]
    
    init(viewModel: ConfirmMandateViewModelProtocol, router: RouterDelegate) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { print("🧨 destroy:", self.self) }
    
    override func viewDidLoad() {
        view.addSubview(subView)
        subView.delegate = self
        subView.dataSource = self
        subView.pin(to: view)
        subView.render(isBusy: true)
        viewModel.loadConfig({ [weak self] error in
            DispatchQueue.main.async {
                if (error.exists) { return }
                self?.subView.render()
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewModel.formCompleted = false
    }
}

extension ConfirmMandateViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return formTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.addTitle(formTypes[indexPath.row].title)
        cell.addContent(formTypes[indexPath.row].content(viewModel.mandate))
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = Primer.theme.colorTheme.main1
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let router = router else { return }
        formTypes[indexPath.row].action(viewModel.mandate, router: router)
    }
}

extension ConfirmMandateViewController: ConfirmMandateViewDelegate {
    var mandate: DirectDebitMandate {
        return viewModel.mandate
    }
    
    func close() {
        self.router?.pop()
    }
    
    func confirm() {
        viewModel.confirmMandateAndTokenize({ [weak self] error in
            DispatchQueue.main.async {
                if (error.exists) { self?.router?.show(.error); return }
                self?.router?.show(.success(type: .directDebit))
            }
        })
    }
}

extension ConfirmMandateViewController: ConfirmMandateViewDataSource {
    var businessDetails: BusinessDetails? {
        return viewModel.businessDetails
    }
    
    var amount: String {
        return viewModel.amount
    }
}

extension ConfirmMandateViewController: ReloadDelegate {
    func reload() {
        subView.render()
    }
}

enum ConfirmMandateFormType: String {
    case name, email, address, iban
    
    var title: String {
        return self.rawValue.uppercased()
    }
    
    func content(_ mandate: DirectDebitMandate) -> String {
        switch self {
        case .name: return "\(mandate.firstName ?? "") \(mandate.lastName ?? "")"
        case .email: return mandate.email ?? ""
        case .address: return mandate.address?.toString() ?? ""
        case .iban: return mandate.iban ?? ""
        }
    }
    
    func action(_ mandate: DirectDebitMandate, router: RouterDelegate) -> Void {
        switch self {
        case .name: return router.show(.form(type: .name(mandate: mandate, popOnComplete: true)))
        case .email: return router.show(.form(type: .email(mandate: mandate, popOnComplete: true)))
        case .address: return router.show(.form(type: .address(mandate: mandate, popOnComplete: true)))
        case .iban: return router.show(.form(type: .iban(mandate: mandate, popOnComplete: true)))
        }
    }
}
