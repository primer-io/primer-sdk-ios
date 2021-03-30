//
//  CheckoutViewController.swift
//  PrimerSDKExample
//
//  Created by Carl Eriksson on 13/01/2021.
//

import UIKit
import PrimerSDK

class CheckoutViewController: UIViewController {
    
    //    let endpoint = "https://arcane-hollows-13383.herokuapp.com"
    let endpoint = "http:localhost:8020"
    
    let amount = 1000
    
    var listOfVaultedPaymentMethods: [PaymentMethodToken] = []
    var primer: Primer?
    
    weak var delegate: ViewControllerDelegate?
    
    let tableView = UITableView()
    let addCardButton = UIButton()
    let addPayPalButton = UIButton()
    let vaultCheckoutButton = UIButton()
    let directCheckoutButton = UIButton()
    let directDebitButton = UIButton()
    
    override func viewDidLoad() {
        title = "Wallet"
        
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
            // Fallback on earlier versions
            view.backgroundColor = .white
        }
        
        var theme: PrimerTheme
        
        let themeColor = UIColor(red: 240/255, green: 97/255, blue: 91/255, alpha: 1)
        
        if #available(iOS 13.0, *) {
            theme = PrimerTheme(
                cornerRadiusTheme: CornerRadiusTheme(textFields: 8),
                colorTheme: PrimerDefaultTheme(
                    //                    text1: .systemTeal,
                    //                    text2: .systemGreen,
                    //                    text3: themeColor,
                    //                    main1: .systemPurple,
                    tint1: themeColor
                    //                    neutral1: .systemPink
                ),
                darkTheme: PrimerDarkTheme(
                    tint1: themeColor
                ),
                layout: PrimerLayout(showTopTitle: true, textFieldHeight: 40),
                //                textFieldTheme: .outlined,
                fontTheme: PrimerFontTheme(mainTitle: .boldSystemFont(ofSize: 24))
            )
        } else {
            theme = PrimerTheme(
                cornerRadiusTheme: CornerRadiusTheme(textFields: 8),
                colorTheme: PrimerDefaultTheme(
                    //                    text3: themeColor,
                    tint1: .systemBlue
                    //                    neutral1: .systemPink
                ),
                layout: PrimerLayout(showTopTitle: false, textFieldHeight: 44),
                textFieldTheme: .outlined,
                fontTheme: PrimerFontTheme(mainTitle: .boldSystemFont(ofSize: 24))
            )
        }
        
        let businessDetails = BusinessDetails(
            name: "My Business",
            address: Address(
                addressLine1: "107 Rue",
                addressLine2: nil,
                city: "Paris",
                state: nil,
                countryCode: "FR",
                postalCode: "75001"
            )
        )
        
        let settings = PrimerSettings(
            delegate: self,
            amount: amount, // todo: make order items override this?
            currency: .GBP,
            countryCode: .gb,
            urlScheme: "https://primer.io/success",
            urlSchemeIdentifier: "primer",
//            isFullScreenOnly: true,
            businessDetails: businessDetails,
            orderItems: [
                OrderItem(name: "Rent scooter", unitAmount: amount, quantity: 1)
            ]
        )
        
        primer = Primer(with: settings)
        
        primer?.setDirectDebitDetails(
            firstName: "John",
            lastName: "Doe",
            email: "test@mail.com",
            iban: "FR1420041010050500013M02606",
            address: Address(
                addressLine1: "1 Rue",
                addressLine2: "",
                city: "Paris",
                state: "",
                countryCode: "FR",
                postalCode: "75001"
            )
        )
        
        primer?.setTheme(theme: theme)
        
        // primer showCheckout(_ controller: UIViewController, flow: PrimerSessionFlow) -> Void
        // primer fetchVaultedPaymentMethods(_ completion: @escaping (Result<[PaymentMethodToken], Error>) -> Void)
        //
        view.addSubview(tableView)
        view.addSubview(addCardButton)
        view.addSubview(addPayPalButton)
        view.addSubview(vaultCheckoutButton)
        view.addSubview(directDebitButton)
        
        //
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
        
        addPayPalButton.setTitle("Add Klarna", for: .normal)
        addPayPalButton.setTitleColor(.white, for: .normal)
        addPayPalButton.layer.cornerRadius = 16
        addPayPalButton.backgroundColor = .lightGray
        addPayPalButton.addTarget(self, action: #selector(showKlarnaForm), for: .touchUpInside)
        
        vaultCheckoutButton.setTitle("Add Payment Method", for: .normal)
        vaultCheckoutButton.setTitleColor(.white, for: .normal)
        vaultCheckoutButton.layer.cornerRadius = 16
        vaultCheckoutButton.backgroundColor = .lightGray
        vaultCheckoutButton.addTarget(self, action: #selector(showCompleteVaultCheckout), for: .touchUpInside)
        
        directDebitButton.setTitle("Add Direct Debit", for: .normal)
        directDebitButton.setTitleColor(.white, for: .normal)
        directDebitButton.layer.cornerRadius = 16
        directDebitButton.backgroundColor = .lightGray
        directDebitButton.addTarget(self, action: #selector(showDirectDebit), for: .touchUpInside)
        
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
        vaultCheckoutButton.bottomAnchor.constraint(equalTo: directDebitButton.topAnchor, constant: -12).isActive = true
        vaultCheckoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        vaultCheckoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        
        directDebitButton.translatesAutoresizingMaskIntoConstraints = false
        directDebitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -48).isActive = true
        directDebitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        directDebitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        
        fetchPaymentMethods()
    }
    
    func fetchPaymentMethods() {
        primer?.fetchVaultedPaymentMethods() { [weak self] result in
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
    
    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
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

// MARK: PrimerDelegate (Required)

extension CheckoutViewController: PrimerDelegate {
    func onCheckoutDismissed() {
        fetchPaymentMethods()
    }
    
    func clientTokenCallback(_ completion: @escaping (Result<CreateClientTokenResponse, Error>) -> Void) {
        guard let url = URL(string: "\(endpoint)/client-token") else {
            return completion(.failure(NetworkError.missingParams))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        callApi(request, completion: { result in
            switch result {
            case .success(let data):
                do {
                    let token = try JSONDecoder().decode(CreateClientTokenResponse.self, from: data)
                    print("🚀🚀🚀 token:", token)
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
        
        guard let url = URL(string: "\(endpoint)/authorize") else {
            return completion(NetworkError.missingParams)
        }
        
        let type = result.paymentInstrumentType
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AuthorizationRequest(paymentMethod: token, amount: amount, type: type.rawValue, capture: true, currencyCode: "GBP")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return completion(NetworkError.missingParams)
        }
        
        print("🐳", result)
        
        completion(nil)
        
        //        callApi(request, completion: { result in
        //            switch result {
        //            case .success: completion(nil)
        //            case .failure(let err): completion(err)
        //            }
        //        })
    }
}

// MARK: TableView

extension CheckoutViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfVaultedPaymentMethods.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentCapturePayment(indexPath.row)
    }
    
    func addSpinner(_ child: SpinnerViewController) {
        tableView.isHidden = true
        addChildViewController(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParentViewController: self)
    }
    
    func removeSpinner(_ child: SpinnerViewController) {
        child.willMove(toParentViewController: nil)
        child.view.removeFromSuperview()
        child.removeFromParentViewController()
        tableView.isHidden = false
    }
    
    func generateRequest(_ token: PaymentMethodToken, capture: Bool) -> URLRequest? {
        guard let url = URL(string: "\(endpoint)/authorize") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AuthorizationRequest(
            paymentMethod: token.token!,
            amount: amount,
            type: token.paymentInstrumentType.rawValue,
            capture: capture,
            currencyCode: "GBP"
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return nil
        }
        
        return request
    }
    
    func showResult(error: Bool) {
        let title = error ? "Error!" : "Success!"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    private func presentCapturePayment(_ index: Int) {
        let result = listOfVaultedPaymentMethods[index]
        let alert = UIAlertController(title: "Pay", message: "Capture the payment, or authorize to capture later.", preferredStyle: .alert)
        let child = SpinnerViewController()
        
        alert.addAction(UIAlertAction(title: "Capture", style: .default, handler: { [weak self] _ in
            self?.addSpinner(child)
            guard let request = self?.generateRequest(result, capture: true) else { return }
            self?.callApi(request, completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.removeSpinner(child)
                        self?.showResult(error: false)
                    case .failure:
                        self?.removeSpinner(child)
                        self?.showResult(error: true)
                    }
                }
            })
        }))
        
        alert.addAction(UIAlertAction(title: "Authorize", style: .default, handler: { [weak self] _ in
            self?.addSpinner(child)
            guard let request = self?.generateRequest(result, capture: false) else { return }
            self?.callApi(request, completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.removeSpinner(child)
                        self?.showResult(error: false)
                    case .failure:
                        self?.removeSpinner(child)
                        self?.showResult(error: true)
                    }
                }
            })
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "primerCell")
        cell.accessoryType = .disclosureIndicator
        cell.tintColor = .white
        let paymentMethodToken = listOfVaultedPaymentMethods[indexPath.row]
        
        //        var title: String
        var subtitle: String
        
        switch paymentMethodToken.paymentInstrumentType {
        case .PAYMENT_CARD:
            //            cell.textLabel?.text = "Card"
            subtitle = "•••• •••• •••• \(paymentMethodToken.paymentInstrumentData?.last4Digits ?? "••••")"
        case .PAYPAL_BILLING_AGREEMENT:
            //            cell.textLabel?.text = "PayPal"
            subtitle = paymentMethodToken.paymentInstrumentData?.externalPayerInfo?.email ?? ""
        case .GOCARDLESS_MANDATE:
            //            cell.textLabel?.text = "Direct Debit"
            subtitle = "Direct Debit"
        case .KLARNA_CUSTOMER_TOKEN:
            subtitle = "Klarna Customer Token"
        default:
            cell.textLabel?.text = ""
            subtitle = ""
        }
        
        cell.addIcon(paymentMethodToken.icon.image)
        cell.addTitle(subtitle)
        
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .light {
                cell.backgroundColor = .white
            } else {
                cell.backgroundColor = .darkGray
            }
        } else {
            cell.backgroundColor = .white
        }
        
        
        return cell
    }
}

extension UITableViewCell {
    
    func addIcon(_ icon: UIImage?) {
        let imageView = UIImageView(image: icon)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 28).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
    }
    
    func addTitle(_ text: String) {
        let title = UILabel()
        title.text = text
        title.translatesAutoresizingMaskIntoConstraints = false
        title.adjustsFontSizeToFitWidth = false
        title.lineBreakMode = .byTruncatingTail
        addSubview(title)
        title.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60).isActive = true
        title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -50).isActive = true
    }
    
}

class SpinnerViewController: UIViewController {
    var spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}
