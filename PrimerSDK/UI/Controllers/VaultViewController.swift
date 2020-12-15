//
//  VaultViewController.swift
//  DemoPrimerSDK
//
//  Created by Carl Eriksson on 06/12/2020.
//

import UIKit
import PassKit

class SpinnerController {
    var spinner = UIActivityIndicatorView()
    
    func showSpinner(superView: UIView) {
        superView.addSubview(spinner)
        spinner.color = .red
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: superView.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: superView.centerYAnchor).isActive = true
        spinner.widthAnchor.constraint(equalToConstant: 20).isActive = true
        spinner.heightAnchor.constraint(equalToConstant: 20).isActive = true
        spinner.startAnimating()
    }
    
    func hideSpinner() {
        spinner.removeFromSuperview()
    }
}

class VaultViewController: UIViewController {
    var tableView = UITableView()
    var payButton = UIButton()
    var applePayButton = UIButton()
    private let cornerRadius: CGFloat = 8.0
    private let bkgColor = UIColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha: 1)
    
    private let checkout: UniversalCheckoutProtocol
    var spinner = UIActivityIndicatorView()
    
    init(_ checkout: UniversalCheckoutProtocol) {
        self.checkout = checkout
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = self.bkgColor
        addSpinner()
        checkout.loadCheckoutConfig({
            error in
            DispatchQueue.main.async {
                self.removeSpinner()
                self.configurePayButton()
                self.configureApplePayButton()
                self.configureTableView()
            }
        })
    }
    
    func configureTableView() {
        view.addSubview(tableView)
        setTableViewDelegates()
        tableView.layer.cornerRadius = 8.0
        tableView.backgroundColor = bkgColor
        tableView.rowHeight = 64
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell3")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell4")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 12).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 12).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -12).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.applePayButton.topAnchor, constant: -12).isActive = true
    }
    
    func setTableViewDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func configurePayButton() {
        view.addSubview(payButton)
        payButton.layer.cornerRadius = cornerRadius
        payButton.setTitle("Pay $" + String(format: "%.2f", (Double(checkout.amount) / 100)), for: .normal)
        payButton.setTitleColor(.white, for: .normal)
        payButton.backgroundColor = .black
        
        payButton.addTarget(self, action: #selector(completePayment), for: .touchUpInside)
        
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12).isActive = true
        payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        payButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        payButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
    }
    
    func configureApplePayButton() {
        applePayButton.layer.cornerRadius = cornerRadius
        applePayButton.setTitle(" Pay", for: .normal)
        applePayButton.backgroundColor = .gray
        view.addSubview(applePayButton)
        applePayButton.translatesAutoresizingMaskIntoConstraints = false
        applePayButton.bottomAnchor.constraint(equalTo: payButton.topAnchor, constant: -12).isActive = true
        applePayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        applePayButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        applePayButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true
        applePayButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
    }
    
    @objc private func completePayment() {
        self.payButton.showSpinner()
        self.checkout.authorizePayment(paymentInstrument: nil, onAuthorizationSuccess: { error in
            
            DispatchQueue.main.async {
                
                var alert: UIAlertController
                
                if let error = error {
                    alert = UIAlertController(title: "Error!", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                } else {
                    alert = UIAlertController(title: "Success!", message: "Purchase completed.", preferredStyle: UIAlertController.Style.alert)
                }
                
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: {
                    _ in
                    self.dismiss(animated: true, completion: nil)
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
}

extension UIButton {
    func showSpinner(_ color: UIColor = .white) {
        self.isUserInteractionEnabled = false
        self.setTitle("", for: .normal)
        let newSpinner = UIActivityIndicatorView()
        newSpinner.color = color
        self.addSubview(newSpinner)
        newSpinner.translatesAutoresizingMaskIntoConstraints = false
        newSpinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        newSpinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        newSpinner.widthAnchor.constraint(equalToConstant: 20).isActive = true
        newSpinner.heightAnchor.constraint(equalToConstant: 20).isActive = true
        newSpinner.startAnimating()
    }
    
    func hideSpinner(_ title: String, spinner: UIActivityIndicatorView) {
        spinner.removeFromSuperview()
        self.setTitle("", for: .normal)
    }
}

extension VaultViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell3")
            cell.textLabel?.text = "John Doe"
            cell.detailTextLabel?.text = "1 Infinite Loop Cupertino, CA 95014, USA"
            cell.accessoryType = .disclosureIndicator
            cell.separatorInset = UIEdgeInsets.zero
            cell.backgroundColor = .white
            cell.tintColor = .black
            cell.textLabel?.textColor = .darkGray
            return cell
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "cell3")
            
            guard let methods = checkout.paymentMethods else { return cell }
            
            let selectedCard = methods.first(where: {
                vm in
                return vm.id == checkout.selectedCard
            })
            
            if (selectedCard != nil) {
                cell.textLabel?.text = "**** **** **** \(selectedCard!.last4)"
            } else {
                cell.textLabel?.text = "select a card"
            }
            
            cell.accessoryType = .disclosureIndicator
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: UIScreen.main.bounds.width)
            cell.backgroundColor = .white
            cell.tintColor = .black
            cell.textLabel?.textColor = .darkGray
            return cell
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath.row == 0) {
            
        } else {
            let vc = VaultPaymentMethodVC.init(self.checkout)
            let td = TransitionDelegate()
            vc.modalPresentationStyle = .custom
            vc.transitioningDelegate = td
            vc.reloadDelegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    private func addSpinner() {
        spinner.color = .black
        view.addSubview(spinner)
        setSpinnerConstraints()
        spinner.startAnimating()
    }
    
    private func setSpinnerConstraints() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        spinner.widthAnchor.constraint(equalToConstant: 20).isActive = true
        spinner.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    private func removeSpinner() {
        self.spinner.removeFromSuperview()
    }
}

extension VaultViewController: ReloadDelegate {
    func reload() {
        self.tableView.reloadData()
    }
}
