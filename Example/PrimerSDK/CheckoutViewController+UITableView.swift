//
//  CheckoutViewController+UITableView.swift
//  PrimerSDK_Example
//
//  Created by Carl Eriksson on 08/04/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import PrimerSDK

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
        guard let url = URL(string: "\(endpoint)/transaction") else { return nil }
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
        case .paymentCard:
            //            cell.textLabel?.text = "Card"
            subtitle = "•••• •••• •••• \(paymentMethodToken.paymentInstrumentData?.last4Digits ?? "••••")"
        case .payPalBillingAgreement:
            //            cell.textLabel?.text = "PayPal"
            subtitle = paymentMethodToken.paymentInstrumentData?.externalPayerInfo?.email ?? ""
        case .goCardlessMandate:
            //            cell.textLabel?.text = "Direct Debit"
            subtitle = "Direct Debit"
        case .klarnaCustomerToken:
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
