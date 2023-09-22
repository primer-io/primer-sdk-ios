//
//  MerchantHeadlessCheckoutNolPayViewController.swift
//  Debug App
//
//  Created by Boris on 12.9.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK
import IQKeyboardManagerSwift

class MerchantHeadlessCheckoutNolPayViewController: UIViewController {
    
    private var nolPayManager: PrimerHeadlessUniversalCheckout.PrimerHeadlessNolPayManager!
    private var linkCardComponent: NolPayLinkCardComponent!
    private var unlinkCardComponent: NolPayUnlinkCardComponent!
    private var getLinkedCardsComponent: NolPayGetLinkedCardsComponent!
    
    // data
    private var linkedCards: [PrimerNolPaymentCard] = []
    
    // UI Components
    private var startLinkingFlowButton: UIButton!
    private var scanCardButton: UIButton!
    private var countryCodeTextField: UITextField!
    private var phoneNumberTextField: UITextField!
    private var submitPhoneNumberButton: UIButton!
    private var otpTextField: UITextField!
    private var submitOTPButton: UIButton!
    
    private var startUnlinkingFlowButton: UIButton!
    private var unlinkPhoneNumberTextField: UITextField!
    private var unlinkCountryCodeTextField: UITextField!
    private var unlinkSubmitPhoneNumberButton: UIButton!
    private var unlinkOtpTextField: UITextField!
    private var unlinkSubmitOTPButton: UIButton!
    
    private var listCardsPhoneNumberTextField: UITextField!
    private var listCardsCountryCodeTextField: UITextField!
    private var listCardsButton: UIButton!
        
    private var linkedCardsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        nolPayManager = PrimerHeadlessUniversalCheckout.PrimerHeadlessNolPayManager(isDebug: true)
        linkCardComponent = nolPayManager.provideNolPayLinkCardComponent()
        linkCardComponent.errorDelegate = self
        linkCardComponent.validationDelegate = self
        linkCardComponent.stepDelegate = self
        
        unlinkCardComponent = nolPayManager.provideNolPayUnlinkCardComponent()
        unlinkCardComponent.errorDelegate = self
        unlinkCardComponent.validationDelegate = self
        unlinkCardComponent.stepDelegate = self
        
        getLinkedCardsComponent = nolPayManager.provideNolPayGetLinkedCardsComponent()
        getLinkedCardsComponent.errorDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enable = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.enable = false
    }
    
    private func setupUI() {
        
        view.backgroundColor = .lightGray
        title = "NolPay integration example"
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Linking
        let linkLabel = UILabel()
        linkLabel.textAlignment = .left
        linkLabel.text = "LINKING FLOW"
        
        startLinkingFlowButton = UIButton(type: .roundedRect)
        startLinkingFlowButton.setTitle(" 1. Start linking flow", for: .normal)
        startLinkingFlowButton.addTarget(self, action: #selector(startLinkingFlowButtonTapped), for: .touchUpInside)
        
        scanCardButton = UIButton(type: .roundedRect)
        scanCardButton.setTitle("2 .Scan NOL NFC Card", for: .normal)
        scanCardButton.addTarget(self, action: #selector(scanCardButtonTapped), for: .touchUpInside)
        
        countryCodeTextField = UITextField()
        countryCodeTextField.placeholder = "3. Country Code"
        countryCodeTextField.borderStyle = .roundedRect
        countryCodeTextField.keyboardType = .phonePad
        
        phoneNumberTextField = UITextField()
        phoneNumberTextField.placeholder = "4. Phone Number"
        phoneNumberTextField.borderStyle = .roundedRect
        phoneNumberTextField.keyboardType = .phonePad
        
        let phoneStackView = UIStackView(arrangedSubviews: [countryCodeTextField, phoneNumberTextField])
        phoneStackView.axis = .horizontal
        phoneStackView.spacing = 10
        phoneStackView.distribution = .fillEqually
        
        submitPhoneNumberButton = UIButton(type: .roundedRect)
        submitPhoneNumberButton.setTitle("5. Submit Phone Number", for: .normal)
        submitPhoneNumberButton.addTarget(self, action: #selector(submitPhoneNumberTapped), for: .touchUpInside)
        
        otpTextField = UITextField()
        otpTextField.placeholder = "6. Enter OTP"
        otpTextField.borderStyle = .roundedRect
        otpTextField.keyboardType = .numberPad
        
        submitOTPButton = UIButton(type: .roundedRect)
        submitOTPButton.setTitle("7. Submit OTP", for: .normal)
        submitOTPButton.addTarget(self, action: #selector(submitLinkOTPTapped), for: .touchUpInside)
        
        // List linked cards
        let listCardsLabel = UILabel()
        listCardsLabel.textAlignment = .left
        listCardsLabel.text = "LIST LINKED CARDS FLOW"
        
        listCardsCountryCodeTextField = UITextField()
        listCardsCountryCodeTextField.placeholder = "Country Code"
        listCardsCountryCodeTextField.borderStyle = .roundedRect
        listCardsCountryCodeTextField.keyboardType = .phonePad
        
        listCardsPhoneNumberTextField = UITextField()
        listCardsPhoneNumberTextField.placeholder = "Phone Number"
        listCardsPhoneNumberTextField.borderStyle = .roundedRect
        listCardsPhoneNumberTextField.keyboardType = .phonePad
        
        let listPhoneStackView = UIStackView(arrangedSubviews: [listCardsCountryCodeTextField, listCardsPhoneNumberTextField])
        listPhoneStackView.axis = .horizontal
        listPhoneStackView.spacing = 10
        listPhoneStackView.distribution = .fillEqually
        
        listCardsButton = UIButton(type: .roundedRect)
        listCardsButton.setTitle("List liked cards", for: .normal)
        listCardsButton.addTarget(self, action: #selector(getLinkedCards), for: .touchUpInside)
        
        // Unlinking
        let unlinkLabel = UILabel()
        unlinkLabel.textAlignment = .left
        unlinkLabel.text = "UNLINKING FLOW"
        
        startUnlinkingFlowButton = UIButton(type: .roundedRect)
        startUnlinkingFlowButton.setTitle("1. Start unlinking flow", for: .normal)
        startUnlinkingFlowButton.addTarget(self, action: #selector(startUnlinkingFlowButtonTapped), for: .touchUpInside)
        
        unlinkCountryCodeTextField = UITextField()
        unlinkCountryCodeTextField.placeholder = "2. Country Code"
        unlinkCountryCodeTextField.borderStyle = .roundedRect
        unlinkCountryCodeTextField.keyboardType = .phonePad
        
        unlinkPhoneNumberTextField = UITextField()
        unlinkPhoneNumberTextField.placeholder = "3 .Phone Number"
        unlinkPhoneNumberTextField.borderStyle = .roundedRect
        unlinkPhoneNumberTextField.keyboardType = .phonePad
        
        let unlinkPhoneStackView = UIStackView(arrangedSubviews: [unlinkCountryCodeTextField, unlinkPhoneNumberTextField])
        unlinkPhoneStackView.axis = .horizontal
        unlinkPhoneStackView.spacing = 10
        unlinkPhoneStackView.distribution = .fillEqually
        
        unlinkSubmitPhoneNumberButton = UIButton(type: .roundedRect)
        unlinkSubmitPhoneNumberButton.setTitle("4. Submit Phone Number", for: .normal)
        unlinkSubmitPhoneNumberButton.addTarget(self, action: #selector(submitUnlinkPhoneNumberTapped), for: .touchUpInside)
        
        unlinkOtpTextField = UITextField()
        unlinkOtpTextField.placeholder = "5. Enter Unlink OTP"
        unlinkOtpTextField.borderStyle = .roundedRect
        unlinkOtpTextField.keyboardType = .numberPad
        
        unlinkSubmitOTPButton = UIButton(type: .roundedRect)
        unlinkSubmitOTPButton.setTitle("6. Submit unlink OTP", for: .normal)
        unlinkSubmitOTPButton.addTarget(self, action: #selector(submitUnlinkOTPTapped), for: .touchUpInside)
                                
        func makeSpacerLabel() -> UILabel {
            let spacerLabel = UILabel()
            spacerLabel.textColor = .black
            spacerLabel.text = "_____________________________"
            return spacerLabel
        }
        setupTableView()
        
        let stackView = UIStackView(arrangedSubviews: [makeSpacerLabel(), linkLabel, startLinkingFlowButton, scanCardButton, phoneStackView, submitPhoneNumberButton, otpTextField, submitOTPButton, makeSpacerLabel(), listCardsLabel, listPhoneStackView, listCardsButton, linkedCardsTableView, makeSpacerLabel(), unlinkLabel, startUnlinkingFlowButton, unlinkPhoneStackView, unlinkSubmitPhoneNumberButton, unlinkOtpTextField, unlinkSubmitOTPButton])
        
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: view.widthAnchor),  // This makes sure our content is only scrollable vertically
            linkedCardsTableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 108),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
            
        ])
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    private func setupTableView() {
        linkedCardsTableView = UITableView()
        linkedCardsTableView.dataSource = self
        linkedCardsTableView.delegate = self
        linkedCardsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cardCell")
    }
    
    // MARK: - Link
    @objc func startLinkingFlowButtonTapped() {
        linkCardComponent.start()
        self.showAlert(title: "Linking started", message: "Linking process started, please tap on 'Scan' button.")
    }
    
    @objc func scanCardButtonTapped() {
        linkCardComponent.submit()
    }
    
    @objc func submitPhoneNumberTapped() {
        guard let countryCode = countryCodeTextField.text, !countryCode.isEmpty,
              let phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty
        else {
            showAlert(title: "Error", message: "Please enter both country code and phone number.")
            return
        }
        
        linkCardComponent.updateCollectedData(data: NolPayLinkCollectableData.phoneData(mobileNumber: phoneNumber,
                                                                                        phoneCountryDiallingCode: countryCode))
    }
    
    @objc func submitLinkOTPTapped() {
        guard let otp = otpTextField.text, !otp.isEmpty
        else {
            showAlert(title: "Error", message: "Please enter the OTP.")
            return
        }
        
        linkCardComponent.updateCollectedData(data: .otpData(otpCode: otp))
    }
    
    // MARK: - Unlink
    @objc func startUnlinkingFlowButtonTapped() {
        unlinkCardComponent.start()
        showAlert(title: "Unlink card", message: "To unlink a card select it from the list of linked cards, enter phone number and country code, and then enter unlink OTP.")
    }
    
    @objc func submitUnlinkPhoneNumberTapped() {
        guard let countryCode = unlinkCountryCodeTextField.text, !countryCode.isEmpty,
              let mobileNumber = unlinkPhoneNumberTextField.text, !mobileNumber.isEmpty
        else {
            showAlert(title: "Error", message: "Please enter both country code and phone number.")
            return
        }
        
        unlinkCardComponent.updateCollectedData(data: .phoneData(mobileNumber: mobileNumber,
                                                                 phoneCountryDiallingCode: countryCode))
    }
    
    @objc func submitUnlinkOTPTapped() {
        guard let otp = unlinkOtpTextField.text, !otp.isEmpty
        else {
            showAlert(title: "Error", message: "Please enter the OTP.")
            return
        }
        
        unlinkCardComponent.updateCollectedData(data: .otpData(otpCode: otp))
    }
    
    // MARK: - Listing of the linked cards
    @objc private func getLinkedCards() {
        
        guard let phoneNumber = self.listCardsPhoneNumberTextField.text, !phoneNumber.isEmpty,
              let countryCode = self.listCardsCountryCodeTextField.text, !countryCode.isEmpty
        else {
            showAlert(title: "Error", message: "Invalid phone number or country code")
            return
        }
        
        getLinkedCardsComponent.getLinkedCardsFor(phoneCountryDiallingCode: countryCode,
                                                  mobileNumber: phoneNumber) { result in
            switch result {
                
            case .success(let cards):
                self.linkedCards = cards
                self.linkedCardsTableView.reloadData()
                self.showAlert(title: "Success", message: "Fetching of the listed cards done, you have: \(cards.count) linked cards")
            case .failure(let error):
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Helper
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension MerchantHeadlessCheckoutNolPayViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return linkedCards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cardCell", for: indexPath)
        cell.textLabel?.text = linkedCards[indexPath.row].cardNumber
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let card = linkedCards[indexPath.row]
        unlinkCardComponent.updateCollectedData(data: NolPayUnlinkCollectableData.cardData(nolPaymentCard: card))
    }
}

// MARK: - PrimerHeadlessErrorableDelegate, PrimerHeadlessValidatableDelegate, PrimerHeadlessStepableDelegate
extension MerchantHeadlessCheckoutNolPayViewController: PrimerHeadlessErrorableDelegate,
                                                        PrimerHeadlessValidatableDelegate,
                                                        PrimerHeadlessStepableDelegate {
    func didValidate(validations: [PrimerValidationError], for data: PrimerSDK.PrimerCollectableData) {
        
        if !validations.isEmpty {
            var message = ""
            for error in validations {
                message += (error.errorDescription ?? error.localizedDescription) + "\n"
            }
            self.showAlert(title: "Validation Error", message: "\(message)")
        } else {
            if data is NolPayLinkCollectableData {
                linkCardComponent.submit()
            } else if data is NolPayUnlinkCollectableData {
                unlinkCardComponent.submit()
            }
        }
    }
    
    func didReceiveError(error: PrimerError) {
        self.showAlert(title: "Error", message: error.errorDescription ?? error.localizedDescription)
    }
    
    func didReceiveStep(step: PrimerHeadlessStep) {
        if let step = step as? NolPayLinkDataStep {
            switch step {
                
            case let .collectPhoneData(cardNumber):
                self.showAlert(title: "Next step", message: "Enter phone number and country code, for card number: \(cardNumber)")
            case .collectOtpData:
                self.showAlert(title: "OTP Sent", message: "Check you SMS inbox")
            case .cardLinked:
                self.showAlert(title: "Success", message: "Card linked successfully! To list it use LIST LINKED CARDS FLOW")
            default: break
            }
            
        } else if let step = step as? NolPayUnlinkDataStep {
            switch step {
                
            case .collectCardData:
                self.showAlert(title: "Next step", message: "Select card to be unlinked")
            case .collectPhoneData:
                self.showAlert(title: "Next step", message: "Enter phone number and country code")
            case .collectOtpData:
                self.showAlert(title: "OTP Sent", message: "Check you SMS inbox")
            case .cardUnlinked:
                self.showAlert(title: "Success", message: "Card unlinked successfully!")
            }
        }
    }
}
