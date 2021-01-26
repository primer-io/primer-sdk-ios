//
//  ConfirmMandateView.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 21/01/2021.
//

import UIKit

protocol ConfirmMandateViewDelegate: class, UITableViewDelegate, UITableViewDataSource {
    func close()
    func confirm()
}

class ConfirmMandateView: UIView {
    internal let indicator = UIActivityIndicatorView()
    private let navBar = UINavigationBar()
    private let title = UILabel()
    private let tableView = UITableView()
    private let companyLabel = UILabel()
    private let legalLabel = UILabel()
    private let amountLabel = UILabel()
    private let confirmButton = UIButton()
    
    weak var delegate: ConfirmMandateViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(navBar)
        addSubview(title)
        addSubview(tableView)
        addSubview(companyLabel)
        addSubview(legalLabel)
        addSubview(amountLabel)
        addSubview(confirmButton)
        addSubview(indicator)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func render(isBusy: Bool = false) {
        subviews.forEach { $0.isHidden = isBusy }
        indicator.isHidden = !isBusy
        
        addNavbar()
        addTitle()
        addTableView()
        addCompanyLabel()
        addLegalLabel()
        addAmountLabel()
        addConfirmButton()
        
        isBusy ? indicator.startAnimating() : indicator.stopAnimating()
    }
}

extension ConfirmMandateView {
    func addIndicator() {
        indicator.pin(to: self)
    }
    
    func addNavbar() {
        let navItem = UINavigationItem()
        let backItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
        navItem.leftBarButtonItem = backItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
        navBar.topItem?.title = "Add bank account"
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    @objc private func close() {
        delegate?.close()
    }
    
    func addTitle() {
        title.text = "Confirm SEPA Direct Debit"
        title.font = .systemFont(ofSize: 20, weight: .regular)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        title.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 12).isActive = true
    }
    
    func addTableView() {
        tableView.backgroundColor = .white
        tableView.delegate = delegate
        tableView.dataSource = delegate
        tableView.rowHeight = 56
        tableView.alwaysBounceVertical = false
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell5")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        tableView.heightAnchor.constraint(equalToConstant: 56 * 4).isActive = true
        tableView.reloadData()
    }
    
    func addCompanyLabel() {
        companyLabel.text = "Company name Assurance, 91 Rue du Faubourg \nSaint-Honoré, 75008 Paris, France"
        companyLabel.numberOfLines = 0
        companyLabel.font = .systemFont(ofSize: 13)
        companyLabel.textColor = .gray
        companyLabel.translatesAutoresizingMaskIntoConstraints = false
        companyLabel.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 24).isActive = true
        companyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
    }
    
    func addLegalLabel() {
        legalLabel.text = "By signing this mandate form, you authorise (C) Company Name  to send instructions to your bank to debit your account and (B) your bank to debit your account in accordance with the instructions from Company Name."
        legalLabel.numberOfLines = 0
        legalLabel.font = .systemFont(ofSize: 10)
        legalLabel.textColor = .gray
        legalLabel.translatesAutoresizingMaskIntoConstraints = false
        legalLabel.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 8).isActive = true
        legalLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        legalLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
    }
    
    func addAmountLabel() {
        amountLabel.text = "£20"
        amountLabel.font = .boldSystemFont(ofSize: 32)
        amountLabel.textColor = .black
        amountLabel.textAlignment = .center
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.topAnchor.constraint(equalTo: legalLabel.bottomAnchor, constant: 12).isActive = true
        amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        amountLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    }
    
    func addConfirmButton() {
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.layer.cornerRadius = 8
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 18).isActive = true
        confirmButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        confirmButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        confirmButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        confirmButton.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
    }
    
    @objc private func onConfirm() {
        confirmButton.setTitle("", for: .normal)
        confirmButton.addSubview(indicator)
        indicator.color = .white
        indicator.pin(to: confirmButton)
        indicator.startAnimating()
        delegate?.confirm()

//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
//            self?.indicator.stopAnimating()
//            self?.indicator.removeFromSuperview()
//            self?.confirmButton.setTitle("Confirm", for: .normal)
//
//        }
    }
}
