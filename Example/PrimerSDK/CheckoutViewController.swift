//
//  CheckoutViewController.swift
//  PrimerSDKExample
//
//  Created by Carl Eriksson on 13/01/2021.
//

import UIKit
import PrimerSDK

class CheckoutViewController: UIViewController {

    let endpoint = "https://us-central1-primerdemo-8741b.cloudfunctions.net"
//    let endpoint = "http:localhost:8020"

    let amount = 200

    var listOfVaultedPaymentMethods: [PaymentMethodToken] = []
    var primer: Primer?

    weak var delegate: ViewControllerDelegate?

    let tableView = UITableView()
    let addCardButton = UIButton()
    let addPayPalButton = UIButton()
    let vaultCheckoutButton = UIButton()
    let directCheckoutButton = UIButton()
    let directDebitButton = UIButton()
    
    deinit { log(logLevel: .debug, message: "🧨 destroyed: \(self.self)") }

    override func viewDidLoad() {
        title = "Wallet"
        initPrimer()
        bindView()
        fetchPaymentMethods()
    }
    
    func fetchPaymentMethods() {
        primer?.fetchVaultedPaymentMethods { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure: print("Error!")
                case .success(let tokens):
                    print("🚀 methods:", tokens)
                    self?.listOfVaultedPaymentMethods = tokens
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
}

// MARK: View-binding

extension CheckoutViewController {
    
    private func bindView() {
        
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .light {
                view.backgroundColor = .white
                tableView.backgroundColor = .white
            } else {
                view.backgroundColor = .darkGray
                tableView.backgroundColor = .darkGray
                tableView.separatorColor = .gray
            }
        } else {
            view.backgroundColor = .white
        }
        
        view.addSubview(tableView)
        view.addSubview(addCardButton)
        view.addSubview(addPayPalButton)
        view.addSubview(vaultCheckoutButton)
        view.addSubview(directDebitButton)

        tableView.delegate = self
        tableView.dataSource = self
        let footer = UIView()

        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .light {
                footer.backgroundColor = .white
            } else {
                footer.backgroundColor = .darkGray
            }
        } else {
            footer.backgroundColor = .white
        }

        tableView.tableFooterView = footer

        addCardButton.setTitle("Add Card", for: .normal)
        addCardButton.setTitleColor(.white, for: .normal)
        addCardButton.layer.cornerRadius = 16
        addCardButton.backgroundColor = .lightGray
        addCardButton.addTarget(self, action: #selector(showCardForm), for: .touchUpInside)

        addPayPalButton.setTitle("Klarna", for: .normal)
        addPayPalButton.setTitleColor(.white, for: .normal)
        addPayPalButton.layer.cornerRadius = 16
        addPayPalButton.backgroundColor = .lightGray
        addPayPalButton.addTarget(self, action: #selector(showKlarnaForm), for: .touchUpInside)

        vaultCheckoutButton.setTitle("Open Wallet", for: .normal)
        vaultCheckoutButton.setTitleColor(.white, for: .normal)
        vaultCheckoutButton.layer.cornerRadius = 16
        vaultCheckoutButton.backgroundColor = .lightGray
        vaultCheckoutButton.addTarget(self, action: #selector(showCompleteVaultCheckout), for: .touchUpInside)

        directDebitButton.setTitle("Add Direct Debit", for: .normal)
        directDebitButton.setTitleColor(.white, for: .normal)
        directDebitButton.layer.cornerRadius = 16
        directDebitButton.backgroundColor = .lightGray
        directDebitButton.addTarget(self, action: #selector(showDirectDebit), for: .touchUpInside)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: addCardButton.topAnchor).isActive = true

        addCardButton.translatesAutoresizingMaskIntoConstraints = false
        addCardButton.bottomAnchor.constraint(equalTo: addPayPalButton.topAnchor, constant: -12).isActive = true
        addCardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        addCardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true

        addPayPalButton.translatesAutoresizingMaskIntoConstraints = false
        addPayPalButton.bottomAnchor.constraint(equalTo: vaultCheckoutButton.topAnchor, constant: -12).isActive = true
        addPayPalButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        addPayPalButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true

        vaultCheckoutButton.translatesAutoresizingMaskIntoConstraints = false
        vaultCheckoutButton.bottomAnchor.constraint(equalTo: directDebitButton.topAnchor, constant: -12).isActive = true
        vaultCheckoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        vaultCheckoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true

        directDebitButton.translatesAutoresizingMaskIntoConstraints = false
        directDebitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -48).isActive = true
        directDebitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        directDebitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
    }

    @objc private func showCardForm() {
        primer?.showCheckout(self, flow: .addCardToVault)
    }
    @objc private func showPayPalForm() {
        primer?.showCheckout(self, flow: .addPayPalToVault)
    }
    @objc private func showKlarnaForm() {
        primer?.showCheckout(self, flow: .addKlarnaToVault)
    }
    @objc private func showCompleteVaultCheckout() {
        primer?.showCheckout(self, flow: .defaultWithVault)
    }
    @objc private func showCompleteDirectCheckout() {
        primer?.showCheckout(self, flow: .completeDirectCheckout)
    }
    @objc private func showDirectDebit() {
        primer?.showCheckout(self, flow: .addDirectDebit)
    }
}
