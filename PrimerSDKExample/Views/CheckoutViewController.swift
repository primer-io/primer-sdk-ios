//
//  CheckoutViewController.swift
//  PrimerSDKExample
//
//  Created by Carl Eriksson on 13/01/2021.
//

import UIKit
import PrimerSDK

class CheckoutViewController: UIViewController {
    
    let amount = 200
    
    var listOfVaultedPaymentMethods: [PaymentMethodToken] = []
    var primer: Primer?
    
    let tableView = UITableView()
    let addCardButton = UIButton()
    let addPayPalButton = UIButton()
    let vaultCheckoutButton = UIButton()
    
    override func viewDidLoad() {
        title = "Wallet"
        view.backgroundColor = .white
        
        let settings = PrimerSettings(
            delegate: self,
            amount: amount,
            currency: .EUR,
            customerId: "customer_1"
        )
        
        primer = Primer(with: settings)
        
        //
        view.addSubview(tableView)
        view.addSubview(addCardButton)
        view.addSubview(addPayPalButton)
        view.addSubview(vaultCheckoutButton)
        
        //
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        addCardButton.setTitle("Add Card", for: .normal)
        addCardButton.setTitleColor(.white, for: .normal)
        addCardButton.backgroundColor = .darkGray
        addCardButton.addTarget(self, action: #selector(showCardForm), for: .touchUpInside)
        
        addPayPalButton.setTitle("Add PayPal", for: .normal)
        addPayPalButton.setTitleColor(.white, for: .normal)
        addPayPalButton.backgroundColor = .systemBlue
        addPayPalButton.addTarget(self, action: #selector(showPayPalForm), for: .touchUpInside)
        
        vaultCheckoutButton.setTitle("Open wallet", for: .normal)
        vaultCheckoutButton.setTitleColor(.white, for: .normal)
        vaultCheckoutButton.backgroundColor = .systemPink
        vaultCheckoutButton.addTarget(self, action: #selector(showCompleteVaultCheckout), for: .touchUpInside)
        
        //
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
        vaultCheckoutButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24).isActive = true
        vaultCheckoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        vaultCheckoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        
        fetchPaymentMethods()
    }
    
    func fetchPaymentMethods() {
        primer?.fetchVaultedPaymentMethods() { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure: print("Error!")
                case .success(let tokens):
                    self?.listOfVaultedPaymentMethods = tokens
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    deinit {
        print("🧨 destroy:", self.self)
    }
    
    @objc private func showCardForm() {
        primer?.showCheckout(self, flow: .addCardToVault)
    }
    @objc private func showPayPalForm() {
        primer?.showCheckout(self, flow: .addPayPalToVault)
    }
    @objc private func showCompleteVaultCheckout() {
        primer?.showCheckout(self, flow: .completeVaultCheckout)
    }
}

// MARK: PrimerCheckoutDelegate (Required)

extension CheckoutViewController: PrimerCheckoutDelegate {
    func onCheckoutDismissed() {
        fetchPaymentMethods()
    }
    
    func clientTokenCallback(_ completion: @escaping (Result<ClientTokenResponse, Error>) -> Void) {
        guard let url = URL(string: "http://192.168.0.50:8020/client-token") else {
            return completion(.failure(NetworkError.missingParams))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        callApi(request, completion: { result in
            switch result {
            case .success(let data):
                do {
                    let token = try JSONDecoder().decode(ClientTokenResponse.self, from: data)
                    completion(.success(token))
                } catch {
                    completion(.failure(NetworkError.serializationError))
                }
            case .failure(let err): completion(.failure(err))
            }
        })
    }
    
    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        guard let token = result.token else { return completion(NetworkError.missingParams) }
        
        guard let url = URL(string: "http://192.168.0.50:8020/authorize") else {
            return completion(NetworkError.missingParams)
        }
        
        let type = result.paymentInstrumentType
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AuthorizationRequest(token: token, amount: amount, type: type.rawValue)
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return completion(NetworkError.missingParams)
        }
        
        callApi(request, completion: { result in
            switch result {
            case .success: completion(nil)
            case .failure(let err): completion(err)
            }
        })
    }
}

// MARK: TableView

extension CheckoutViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfVaultedPaymentMethods.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "primerCell")
        let paymentMethodToken = listOfVaultedPaymentMethods[indexPath.row]
        
        var title: String
        var subtitle: String
        
        switch paymentMethodToken.paymentInstrumentType {
        case .PAYMENT_CARD:
            title = "Card"
            subtitle = "**** **** **** \(paymentMethodToken.paymentInstrumentData?.last4Digits ?? "****")"
        case .PAYPAL_BILLING_AGREEMENT:
            title = "PayPal"
            subtitle = paymentMethodToken.paymentInstrumentData?.externalPayerInfo?.email ?? ""
        default:
            title = ""
            subtitle = ""
        }
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        cell.accessoryType = .disclosureIndicator
        cell.tintColor = .black
        cell.textLabel?.textColor = .darkGray
        return cell
    }
}
