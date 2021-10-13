//
//  ConfirmMandateView.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 21/01/2021.
//

#if canImport(UIKit)

import UIKit

internal protocol ConfirmMandateViewDelegate: UITableViewDelegate, UITableViewDataSource {
    func close()
    func confirm()
}

internal protocol ConfirmMandateViewDataSource: AnyObject {
    var businessDetails: BusinessDetails? { get }
    var amount: String { get }
}

internal class ConfirmMandateView: PrimerView {

    internal let indicator = UIActivityIndicatorView()
    private let navBar = UINavigationBar()
    private let title = UILabel()
    private let tableView = ConfirmMandateTableView()
    private let companyLabel = UILabel()
    private let legalLabel = UILabel()
    private let amountLabel = UILabel()
    private let button = UIButton()

    weak var delegate: ConfirmMandateViewDelegate?
    weak var dataSource: ConfirmMandateViewDataSource?

    func render(isBusy: Bool = false) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        addSubview(navBar)
        addSubview(title)
        addSubview(tableView)
        addSubview(companyLabel)
        addSubview(legalLabel)
        addSubview(amountLabel)
        addSubview(button)
        addSubview(indicator)

        subviews.forEach { $0.isHidden = isBusy }
        navBar.isHidden = false
        indicator.color = theme.text.system.color
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

internal extension ConfirmMandateView {
    func addIndicator() {
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.topAnchor.constraint(equalTo: topAnchor).isActive = true
        indicator.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        indicator.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        indicator.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    func addNavbar() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let navItem = UINavigationItem()
        let backItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))
        backItem.tintColor = theme.text.system.color
        navItem.leftBarButtonItem = backItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
        navBar.topItem?.title = Content.ConfirmMandateView.NavTitle
        navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: theme.text.default.color]
        navBar.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 13.0, *) {
            navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        } else {
            navBar.topAnchor.constraint(equalTo: topAnchor, constant: 18).isActive = true
        }

        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }

    @objc private func close() {
        delegate?.close()
    }

    func addTitle() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        title.text = Content.ConfirmMandateView.Title
        title.textColor = theme.text.title.color
        title.font = UIFont.systemFont(ofSize: 20)
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        title.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        title.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 12).isActive = true
        title.leadingAnchor.constraint(
            equalTo: leadingAnchor,
            constant: theme.view.safeMargin
        ).isActive = true
        title.trailingAnchor.constraint(
            equalTo: trailingAnchor,
            constant: -theme.view.safeMargin
        ).isActive = true
    }

    func addTableView() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        tableView.render()
        tableView.delegate = delegate
        tableView.dataSource = delegate
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(
            equalTo: title.bottomAnchor,
            constant: theme.view.safeMargin
        ).isActive = true
        tableView.leadingAnchor.constraint(
            equalTo: leadingAnchor,
            constant: theme.view.safeMargin
        ).isActive = true
        tableView.trailingAnchor.constraint(
            equalTo: trailingAnchor,
            constant: -theme.view.safeMargin
        ).isActive = true
        tableView.heightAnchor.constraint(
            equalToConstant: theme.view.safeMargin * 4
        ).isActive = true
    }

    func addCompanyLabel() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        guard let business = dataSource?.businessDetails else { return }
        companyLabel.text = business.name + ", " + business.address.toString()
        companyLabel.numberOfLines = 0
        companyLabel.font = .systemFont(ofSize: 13)
        companyLabel.textColor = theme.text.subtitle.color
        companyLabel.translatesAutoresizingMaskIntoConstraints = false
        companyLabel.topAnchor.constraint(
            equalTo: tableView.bottomAnchor,
            constant: 24 // TODO: make dynamic following UI update
        ).isActive = true
        companyLabel.leadingAnchor.constraint(
            equalTo: leadingAnchor,
            constant: theme.view.safeMargin
        ).isActive = true
    }

    func addLegalLabel() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        guard let business = dataSource?.businessDetails else { return }

        legalLabel.text =
            NSLocalizedString("primer-form-view-confirm-mandate-legal-text-part-1",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "By signing this mandate form, you authorise (C) - ",
                                     comment: "By signing this mandate form, you authorise (C) - ") +
            " \(business.name) " +
            NSLocalizedString("primer-form-view-confirm-mandate-legal-text-part-2",
                              tableName: nil,
                              bundle: Bundle.primerResources,
                              value: "to send instructions to your bank to debit your account and (B) your bank to debit your account in accordance with the instructions from",
                              comment: "to send instructions to your bank to debit your account and (B) your bank to debit your account in accordance with the instructions from") +
            " \(business.name)."

        legalLabel.numberOfLines = 0
        legalLabel.lineBreakMode = .byWordWrapping
        legalLabel.font = .systemFont(ofSize: 10)
        legalLabel.textColor = theme.text.subtitle.color
        legalLabel.translatesAutoresizingMaskIntoConstraints = false
        legalLabel.topAnchor.constraint(equalTo: companyLabel.bottomAnchor, constant: 8).isActive = true
        legalLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.view.safeMargin)
            .isActive = true
        legalLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.view.safeMargin)
            .isActive = true
    }

    func addAmountLabel() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        guard let amount = dataSource?.amount else { return }
        amountLabel.text = amount
        amountLabel.font = .boldSystemFont(ofSize: 32)
        amountLabel.textColor = theme.text.title.color
        amountLabel.textAlignment = .center
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.topAnchor.constraint(equalTo: legalLabel.bottomAnchor, constant: 12).isActive = true
        amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.view.safeMargin)
            .isActive = true
        amountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.view.safeMargin)
            .isActive = true
    }

    func addConfirmButton() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        // TODO: fix injection of string values
        button.setTitle(Content.ConfirmMandateView.SubmitButtonTitle, for: .normal)
        button.setTitleColor(theme.mainButton.text.color, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = theme.mainButton.color(for: .enabled)
        button.layer.cornerRadius = theme.mainButton.cornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.view.safeMargin)
            .isActive = true
        button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.view.safeMargin)
            .isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32).isActive = true
        button.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        let image = ImageName.lock.image?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView()
        imageView.tintColor = theme.mainButton.text.color
        imageView.image = image
        button.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16).isActive = true
    }

    @objc private func onConfirm() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        indicator.removeFromSuperview()
        addSubview(indicator)
        button.setTitle("", for: .normal)
        button.addSubview(indicator)
        indicator.color = theme.mainButton.text.color
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.topAnchor.constraint(equalTo: button.topAnchor).isActive = true
        indicator.leadingAnchor.constraint(equalTo: button.leadingAnchor).isActive = true
        indicator.trailingAnchor.constraint(equalTo: button.trailingAnchor).isActive = true
        indicator.bottomAnchor.constraint(equalTo: button.bottomAnchor).isActive = true
        indicator.startAnimating()
        delegate?.confirm()
    }
}

internal class ConfirmMandateTableView: UITableView {

    func render() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        rowHeight = 60.0 // TODO: make dynamic after UI update
        backgroundColor = theme.view.backgroundColor
        layer.cornerRadius = theme.view.cornerRadius
        alwaysBounceVertical = false
        tableFooterView = UIView()
        register(UITableViewCell.self, forCellReuseIdentifier: "cell5")
        reloadData()
    }
}

#endif
