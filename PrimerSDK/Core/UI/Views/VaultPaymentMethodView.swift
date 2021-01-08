//
//  VaultPaymentMethodView.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 06/01/2021.
//

import UIKit


class VaultPaymentMethodView: UIView {
    let tableView = UITableView()
    let backButton = UIButton()
    let mainTitle = UILabel()
    let editButton = UIButton()
    let addButton = UIButton()
    
    let theme: PrimerTheme
    
    init(frame: CGRect, delegate: UITableViewDelegate, dataSource: UITableViewDataSource, theme: PrimerTheme) {
        self.theme = theme
        super.init(frame: frame)
        tableView.delegate = delegate
        tableView.dataSource = dataSource
        
        addSubview(tableView)
        addSubview(backButton)
        addSubview(mainTitle)
        addSubview(editButton)
        addSubview(addButton)
        
        configureTableView()
        configureBackButton()
        configureMainTitle()
        configureEditButton()
        configureAddButton()
        
        setBackButtonContraints()
        setMainTitleConstraints()
        setEditButtonConstraints()
        setAddButtonConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    
    private func configureTableView() {
        tableView.layer.cornerRadius = 8.0
        tableView.backgroundColor = theme.backgroundColor
        tableView.rowHeight = 64
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell5")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: mainTitle.bottomAnchor, constant: 12).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        tableView.heightAnchor.constraint(equalToConstant: 64 * 3).isActive = true
    }
    
    private func configureMainTitle() {
        mainTitle.text = "Other ways to pay"
    }
    
    private func configureEditButton() {
        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(.systemBlue, for: .normal)
        editButton.setTitleColor(.black, for: .highlighted)
        editButton.contentHorizontalAlignment = .right
        editButton.backgroundColor = theme.backgroundColor
    }
    
    private func configureBackButton() {
        if #available(iOS 13.0, *) {
            backButton.setImage(UIImage(named: "back"), for: .normal)
//            backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        } else {
            // Fallback on earlier versions
            backButton.setImage(UIImage(named: "back"), for: .normal)
        }
        backButton.backgroundColor = theme.backgroundColor
    }
    
    private func configureAddButton() {
        addButton.setTitle("Add new card", for: .normal)
        addButton.setTitleColor(.systemBlue, for: .normal)
        addButton.setTitleColor(.black, for: .highlighted)
        addButton.contentHorizontalAlignment = .left
    }
    
    //
    
    private func setBackButtonContraints() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.topAnchor.constraint(equalTo: topAnchor, constant: 24).isActive = true
        backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
    }
    
    private func setMainTitleConstraints() {
        mainTitle.translatesAutoresizingMaskIntoConstraints = false
        mainTitle.topAnchor.constraint(equalTo: topAnchor, constant: 24).isActive = true
        mainTitle.heightAnchor.constraint(equalToConstant: 24).isActive = true
        mainTitle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
    private func setEditButtonConstraints() {
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.topAnchor.constraint(equalTo: topAnchor, constant: 24).isActive = true
        editButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24).isActive = true
        editButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        editButton.widthAnchor.constraint(equalToConstant: editButton.intrinsicContentSize.width).isActive = true
    }
    
    private func setAddButtonConstraints() {
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 12).isActive = true
        addButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        addButton.widthAnchor.constraint(equalToConstant: addButton.intrinsicContentSize.width).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: addButton.intrinsicContentSize.height).isActive = true
    }
}
