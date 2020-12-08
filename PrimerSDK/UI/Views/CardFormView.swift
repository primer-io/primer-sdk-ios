//
//  CardFormView.swift
//  PrimerScannerDemo
//
//  Created by Carl Eriksson on 29/11/2020.
//

import UIKit

class CardFormView: UIView {
    
    private let fieldColor = UIColor(red: 254.0/255.0, green: 254.0/255.0, blue: 254.0/255.0, alpha: 1)
    private let fieldHeight: CGFloat = 44.0
    private let cornerRadius: CGFloat = 8.0
    
    var title = UILabel()
    var submitButton = UIButton()
    var scannerButton = UIButton()
    
    let nameTF = UITextField()
    let cardTF = UITextField()
    let expTF = UITextField()
    let cvcTF = UITextField()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(title)
        addSubview(submitButton)
        addSubview(scannerButton)
        
        addSubview(nameTF)
        addSubview(cardTF)
        addSubview(expTF)
        addSubview(cvcTF)
        
        configureTitle()
        configureSubmitButton()
        configureScannerButton()
        
        configureNameTF()
        configureCardTF()
        configureExpTF()
        configureCvcTF()
        
        setTitleConstraints()
        setSubmitButtonConstraints()
        setScannerButtonConstraints()
        
        setNameTFConstraints()
        setCardTFConstraints()
        setExpTFConstraints()
        setCvcTFConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let padding = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    
    func configureTitle() {
        title.text = "Add card"
        title.font = title.font.withSize(20)
    }
    
    private func configureSubmitButton() {
        submitButton.layer.cornerRadius = cornerRadius
        submitButton.setTitle("Add card", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.backgroundColor = .black
    }
    
    private func configureScannerButton() {
        scannerButton.setTitle("Scan card", for: .normal)
        scannerButton.setTitleColor(.systemBlue, for: .normal)
        scannerButton.setTitleColor(.black, for: .highlighted)
        scannerButton.contentHorizontalAlignment = .right
    }
    
    private func configureNameTF() {
        nameTF.placeholder = "John Doe"
        nameTF.layer.cornerRadius = cornerRadius
        nameTF.textColor = .darkGray
        nameTF.tintColor = .black
        nameTF.backgroundColor = fieldColor
        nameTF.setLeftPaddingPoints(10)
    }
    
    private func configureCardTF() {
        cardTF.placeholder = "4242 4242 4242 4242"
        cardTF.layer.cornerRadius = cornerRadius
        cardTF.textColor = .darkGray
        cardTF.tintColor = .black
        cardTF.backgroundColor = fieldColor
        cardTF.setLeftPaddingPoints(10)
        cardTF.keyboardType = UIKeyboardType.numberPad
    }
    
    private func configureExpTF() {
        expTF.placeholder = "12/20"
        expTF.layer.cornerRadius = cornerRadius
        expTF.textColor = .darkGray
        expTF.tintColor = .black
        expTF.backgroundColor = fieldColor
        expTF.setLeftPaddingPoints(10)
        expTF.keyboardType = UIKeyboardType.numberPad
    }
    
    private func configureCvcTF() {
        cvcTF.placeholder = "CVV"
        cvcTF.layer.cornerRadius = cornerRadius
        cvcTF.textColor = .darkGray
        cvcTF.tintColor = .black
        cvcTF.backgroundColor = fieldColor
        cvcTF.setLeftPaddingPoints(10)
        cvcTF.keyboardType = UIKeyboardType.numberPad
    }
    
    private func setTitleConstraints() {
        title.translatesAutoresizingMaskIntoConstraints = false
        title.topAnchor.constraint(equalTo: topAnchor, constant: 18).isActive = true
        title.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
    private func setSubmitButtonConstraints() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: expTF.bottomAnchor, constant: 12).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: fieldHeight + 16).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        submitButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
    }
    
    private func setScannerButtonConstraints() {
        scannerButton.translatesAutoresizingMaskIntoConstraints = false
        scannerButton.topAnchor.constraint(equalTo: topAnchor, constant: 24).isActive = true
        scannerButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24).isActive = true
        scannerButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        scannerButton.widthAnchor.constraint(equalToConstant: scannerButton.intrinsicContentSize.width).isActive = true
    }
    
    private func setNameTFConstraints() {
        nameTF.translatesAutoresizingMaskIntoConstraints = false
        nameTF.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 18).isActive = true
        nameTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        nameTF.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        nameTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
    }
    
    private func setCardTFConstraints() {
        cardTF.translatesAutoresizingMaskIntoConstraints = false
        cardTF.topAnchor.constraint(equalTo: nameTF.bottomAnchor, constant: 12).isActive = true
        cardTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        cardTF.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        cardTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
    }
    
    private func setExpTFConstraints() {
        expTF.translatesAutoresizingMaskIntoConstraints = false
        expTF.topAnchor.constraint(equalTo: cardTF.bottomAnchor, constant: 12).isActive = true
        expTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        expTF.trailingAnchor.constraint(equalTo: centerXAnchor, constant: -6).isActive = true
        expTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
    }
    
    private func setCvcTFConstraints() {
        cvcTF.translatesAutoresizingMaskIntoConstraints = false
        cvcTF.topAnchor.constraint(equalTo: cardTF.bottomAnchor, constant: 12).isActive = true
        cvcTF.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 6).isActive = true
        cvcTF.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        cvcTF.heightAnchor.constraint(equalToConstant: fieldHeight).isActive = true
    }
    
}
