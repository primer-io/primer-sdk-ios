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

protocol ConfirmMandateViewDataSource: class {
    var businessDetails: BusinessDetails? { get }
    var amount: String { get }
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
    weak var dataSource: ConfirmMandateViewDataSource?
    
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
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        indicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
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
        navBar.topItem?.title = "Add bank account".localized()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    @objc private func close() {
        delegate?.close()
    }
    
    func addTitle() {
        title.text = "Confirm SEPA Direct Debit".localized()
        title.font = .systemFont(ofSize: 20, weight: .regular)
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        title.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        title.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 12).isActive = true
        title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
    }
    
    func addTableView() {
//        tableView.backgroundColor = delegate.theme.colorTheme.main1
        tableView.delegate = delegate
        tableView.dataSource = delegate
        tableView.rowHeight = 56
        tableView.backgroundColor = Primer.theme.colorTheme.main1
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
        guard let business = dataSource?.businessDetails else { return }
        companyLabel.text = business.name + ", " + business.address.toString()
        companyLabel.numberOfLines = 0
        companyLabel.font = .systemFont(ofSize: 13)
        companyLabel.textColor = Primer.theme.colorTheme.disabled1
        companyLabel.translatesAutoresizingMaskIntoConstraints = false
        companyLabel.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 24).isActive = true
        companyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
    }
    
    func addLegalLabel() {
        guard let business = dataSource?.businessDetails else { return }
        legalLabel.text =
            "By signing this mandate form, you authorise (C) ".localized() +
            "\(business.name) " + "to send instructions to your bank to debit your account and (B) your bank to debit your account in accordance with the instructions from ".localized() +
            "\(business.name)."
        legalLabel.numberOfLines = 0
        legalLabel.lineBreakMode = .byWordWrapping
        legalLabel.font = .systemFont(ofSize: 10)
        legalLabel.textColor = Primer.theme.colorTheme.disabled1
        legalLabel.translatesAutoresizingMaskIntoConstraints = false
        legalLabel.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 8).isActive = true
        legalLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        legalLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
    }
    
    func addAmountLabel() {
        guard let amount = dataSource?.amount else { return }
        amountLabel.text = amount
        amountLabel.font = .boldSystemFont(ofSize: 32)
        amountLabel.textColor = Primer.theme.colorTheme.text1
        amountLabel.textAlignment = .center
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.topAnchor.constraint(equalTo: legalLabel.bottomAnchor, constant: 12).isActive = true
        amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
        amountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
    }
    
    func addConfirmButton() {
        confirmButton.setTitle("Confirm".localized(), for: .normal)
        confirmButton.setTitleColor(Primer.theme.colorTheme.text2, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        confirmButton.backgroundColor = Primer.theme.colorTheme.tint1
        confirmButton.layer.cornerRadius = 8
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30).isActive = true
        confirmButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        confirmButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        confirmButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
        confirmButton.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        let imageView = UIImageView(image: ImageName.lock.image)
        confirmButton.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerYAnchor.constraint(equalTo: confirmButton.centerYAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: confirmButton.trailingAnchor, constant: -16).isActive = true
    }
    
    @objc private func onConfirm() {
        indicator.removeFromSuperview()
        addSubview(indicator)
        confirmButton.setTitle("", for: .normal)
        confirmButton.addSubview(indicator)
        indicator.color = Primer.theme.colorTheme.text2
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
