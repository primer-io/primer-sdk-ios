//
//  ConfirmMandateViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 10/01/2021.
//

#if canImport(UIKit)

import UIKit

class ConfirmMandateViewController: UIViewController {

    var subView: ConfirmMandateView = ConfirmMandateView()

    let formTypes: [ConfirmMandateFormType] = [.name, .email, .address, .iban]

    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
    }

    override func viewDidLoad() {
        view.addSubview(subView)
        subView.delegate = self
        subView.dataSource = self
        subView.pin(to: view)
        subView.render(isBusy: true)
        
        let viewModel: ConfirmMandateViewModelProtocol = DependencyContainer.resolve()
        viewModel.loadConfig({ [weak self] error in
            DispatchQueue.main.async {
                if error.exists {
                    let router: RouterDelegate = DependencyContainer.resolve()
                    router.show(.error(error: PrimerError.failedToLoadSession))
                    return
                }
                self?.subView.render()
            }
        })
        view.layoutIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        var viewModel: ConfirmMandateViewModelProtocol = DependencyContainer.resolve()
        viewModel.formCompleted = false
    }
}

extension ConfirmMandateViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return formTypes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel: ConfirmMandateViewModelProtocol = DependencyContainer.resolve()
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.addTitle(formTypes[indexPath.row].title, theme: theme)
        cell.addContent(formTypes[indexPath.row].content(viewModel.mandate), theme: theme)
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = theme.colorTheme.main1
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewModel: ConfirmMandateViewModelProtocol = DependencyContainer.resolve()
        let router: RouterDelegate = DependencyContainer.resolve()
        
        tableView.deselectRow(at: indexPath, animated: true)
        formTypes[indexPath.row].action(viewModel.mandate, router: router)
    }
}

extension ConfirmMandateViewController: ConfirmMandateViewDelegate {
    var mandate: DirectDebitMandate {
        let viewModel: ConfirmMandateViewModelProtocol = DependencyContainer.resolve()
        return viewModel.mandate
    }

    func close() {
        dismiss(animated: true, completion: nil)
//        let alert = UIAlertController(
//            title: "Do you want to cancel adding a bank account?".localized(),
//            message: "Your saved data will be erased.".localized(),
//            preferredStyle: .alert
//        )
//
//        alert.addAction(UIAlertAction(title: "Back", style: .cancel, handler: nil))
//        alert.addAction(UIAlertAction(title: "Erase", style: .destructive, handler: { [weak self] action in
//            self?.viewModel.eraseData()
//            self?.router.pop()
//        }))
//
//        present(alert, animated: true, completion: nil)
    }

    func confirm() {
        let viewModel: ConfirmMandateViewModelProtocol = DependencyContainer.resolve()
        viewModel.confirmMandateAndTokenize({ [weak self] error in
            DispatchQueue.main.async {
                let router: RouterDelegate = DependencyContainer.resolve()
                if error.exists {
                    router.show(.error(error: PrimerError.directDebitSessionFailed))
                    return
                } else {
                    router.show(.success(type: .directDebit))
                }
            }
        })
    }
}

extension ConfirmMandateViewController: ConfirmMandateViewDataSource {
    var businessDetails: BusinessDetails? {
        let viewModel: ConfirmMandateViewModelProtocol = DependencyContainer.resolve()
        return viewModel.businessDetails
    }

    var amount: String {
        let viewModel: ConfirmMandateViewModelProtocol = DependencyContainer.resolve()
        return viewModel.amount
    }
}

extension ConfirmMandateViewController: ReloadDelegate {
    func reload() {
        subView.render()
        view.layoutIfNeeded()
    }
}

enum ConfirmMandateFormType: String {
    case name, email, address, iban

    var title: String {
        switch self {
        case .name:
            return NSLocalizedString("primer-confirm-mandate-form-title",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "NAME",
                                     comment: "NAME - Confirm Mandate Title")
                .uppercased()

        case .email:
            return NSLocalizedString("primer-confirm-mandate-form-email",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "EMAIL",
                                     comment: "EMAIL - Confirm Mandate Title")
                .uppercased()

        case .address:
            return NSLocalizedString("primer-confirm-mandate-form-address",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "ADDRESS",
                                     comment: "ADDRESS - Confirm Mandate Title")
                .uppercased()

        case .iban:
            return NSLocalizedString("primer-confirm-mandate-form-iban",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "IBAN",
                                     comment: "IBAN - Confirm Mandate Title")
                .uppercased()

        }
    }

    func content(_ mandate: DirectDebitMandate) -> String {
        switch self {
        case .name: return "\(mandate.firstName ?? "") \(mandate.lastName ?? "")"
        case .email: return mandate.email ?? ""
        case .address: return mandate.address?.toString() ?? ""
        case .iban: return mandate.iban ?? ""
        }
    }

    func action(_ mandate: DirectDebitMandate, router: RouterDelegate) {
        switch self {
        case .name: return router.show(.form(type: .name(mandate: mandate, popOnComplete: true)))
        case .email: return router.show(.form(type: .email(mandate: mandate, popOnComplete: true)))
        case .address: return router.show(.form(type: .address(mandate: mandate, popOnComplete: true)))
        case .iban: return router.show(.form(type: .iban(mandate: mandate, popOnComplete: true)))
        }
    }
}

#endif
