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
    @Dependency private(set) var viewModel: ConfirmMandateViewModelProtocol
    @Dependency private(set) var router: RouterDelegate
    @Dependency private(set) var theme: PrimerThemeProtocol

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
        viewModel.loadConfig({ [weak self] error in
            DispatchQueue.main.async {
                if error.exists {
                    self?.router.show(.error(message: "failed to load session, please close and try again."))
                    return
                }
                self?.subView.render()
            }
        })
        view.layoutIfNeeded()
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
        cell.addTitle(formTypes[indexPath.row].title, theme: theme)
        cell.addContent(formTypes[indexPath.row].content(viewModel.mandate), theme: theme)
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = theme.colorTheme.main1
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        formTypes[indexPath.row].action(viewModel.mandate, router: router)
    }
}

extension ConfirmMandateViewController: ConfirmMandateViewDelegate {
    var mandate: DirectDebitMandate {
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
//        router.show(.error(message: PrimerError.DirectDebitSessionFailed.rawValue.localized()))
        viewModel.confirmMandateAndTokenize({ [weak self] error in
            DispatchQueue.main.async {
                if error.exists {
                    self?.router.show(.error(message: PrimerError.directDebitSessionFailed.localizedDescription
                    ))
                    return
                }
                self?.router.show(.success(type: .directDebit))
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
        view.layoutIfNeeded()
    }
}

enum ConfirmMandateFormType: String {
    case name, email, address, iban

    var title: String {
        return self.rawValue.localized().uppercased()
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
