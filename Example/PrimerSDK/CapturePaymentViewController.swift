//
//  CapturePaymentViewController.swift
//  PrimerSDKExample
//
//  Created by Carl Eriksson on 19/01/2021.
//

import UIKit

class CapturePaymentViewController: UIViewController {
    let subView = CapturePaymentView()

    var request: AuthorizationRequest?

    override func viewDidLoad() {
        view.backgroundColor = .white
        subView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subView)
        subView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        subView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        subView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        subView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        guard let amount = request?.amount else { return }
        subView.addLabel(amount)
        subView.addButton()
        subView.button.addTarget(self, action: #selector(authorizePayment), for: .touchUpInside)
    }

    @objc func authorizePayment() {
        print("loading 🤖")
        guard let body = request else { return }
        guard let url = URL(string: "http://localhost:8020/authorize") else { return }
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return
        }

        callApi(request, completion: { result in
            switch result {
            case .success:
                print("done 🚀")
                return
            case .failure:
                return
            }
        })
    }
}

// MARK: View

class CapturePaymentView: UIView {
    var button = UIButton()
}

extension CapturePaymentView {

    func addLabel(_ amount: Int) {
        let label = UILabel()
        label.text = amount.asCurrency
        label.font = .boldSystemFont(ofSize: 36)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: centerYAnchor, constant: -24).isActive = true
    }

    func addButton() {
        button.setTitle("Pay", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        button.widthAnchor.constraint(equalToConstant: 132).isActive = true
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        button.centerXAnchor.constraint(equalTo:centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo:centerYAnchor, constant: 24).isActive = true
    }
}

extension Int {
    var asCurrency: String {
        return "€\(self/100).00"
    }
}
