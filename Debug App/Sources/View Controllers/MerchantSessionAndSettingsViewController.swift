//
//  MerchantSessionAndSettingsViewController.swift
//  Debug App
//
//  Created by Evangelos Pittas on 7/2/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import PrimerSDK
import UIKit

var environment: Environment = .sandbox
var apiVersion: PrimerApiVersion = .V2_4
var customDefinedApiKey: String?
var performPaymentAfterVaulting: Bool = false
var paymentSessionType: MerchantMockDataManager.SessionType = .generic

class MerchantSessionAndSettingsViewController: UIViewController {
    enum RenderMode: Int {
        case createClientSession = 0
        case clientToken
        case testScenario
    }

    // MARK: Stack Views

    @IBOutlet var environmentStackView: UIStackView!
    @IBOutlet var testParamsGroupStackView: UIStackView!
    @IBOutlet var apiKeyStackView: UIStackView!
    @IBOutlet var klarnaEMDStackView: UIStackView!
    @IBOutlet var clientTokenStackView: UIStackView!
    @IBOutlet var sdkSettingsStackView: UIStackView!
    @IBOutlet var orderStackView: UIStackView!
    @IBOutlet var customerStackView: UIStackView!
    @IBOutlet var surchargeGroupStackView: UIStackView!

    // MARK: Testing Mode Inputs

    @IBOutlet var testingModeSegmentedControl: UISegmentedControl!

    // MARK: Environment Inputs

    @IBOutlet var environmentSegmentedControl: UISegmentedControl!
    @IBOutlet var apiKeyTextField: UITextField!
    @IBOutlet var clientTokenTextField: UITextField!
    @IBOutlet var metadataTextField: UITextField!

    // MARK: Test Inputs

    @IBOutlet var testScenarioTextField: UITextField!
    @IBOutlet var testResultSegmentedControl: UISegmentedControl!
    @IBOutlet var testParamsStackView: UIStackView!
    @IBOutlet var testResultStackView: UIStackView!
    @IBOutlet var testFailureStackView: UIStackView!
    @IBOutlet var testFailureFlowTextField: UITextField!
    @IBOutlet var testErrorIdTextField: UITextField!
    @IBOutlet var testErrorDescriptionTextField: UITextField!
    @IBOutlet var test3DSStackView: UIStackView!
    @IBOutlet var test3DSScenarioTextField: UITextField!

    // MARK: SDK Settings Inputs

    @IBOutlet var checkoutFlowSegmentedControl: UISegmentedControl!
    @IBOutlet var vaultingFlowSegmentedControl: UISegmentedControl!
    @IBOutlet var merchantNameTextField: UITextField!
    @IBOutlet var applyThemingSwitch: UISwitch!
    @IBOutlet var disableSuccessScreenSwitch: UISwitch!
    @IBOutlet var disableErrorScreenSwitch: UISwitch!
    @IBOutlet var gesturesDismissalSwitch: UISwitch!
    @IBOutlet var closeButtonDismissalSwitch: UISwitch!
    @IBOutlet var disableInitScreenSwitch: UISwitch!
    @IBOutlet var enableCVVRecaptureFlowSwitch: UISwitch!

    // MARK: Apple Pay Inputs

    @IBOutlet var applePayCaptureBillingAddressSwitch: UISwitch!
    @IBOutlet var applePayCheckProvidedNetworksSwitch: UISwitch!

    @IBOutlet var applePayBillingControlStackView: UIStackView!
    @IBOutlet var applePayBillingContactNameSwitch: UISwitch!
    @IBOutlet var applePayBillingContactEmailSwitch: UISwitch!
    @IBOutlet var applePayBillingContactPhoneSwitch: UISwitch!
    @IBOutlet var applePayBillingContactPostalAddressSwitch: UISwitch!

    @IBOutlet var applePayShippingControlStackView: UIStackView!
    @IBOutlet var applePayShippingDetailsSwitch: UISwitch!
    @IBOutlet var applePayRequireShippingMethodSwitch: UISwitch!
    @IBOutlet var applePayShippingContactNameSwitch: UISwitch!
    @IBOutlet var applePayShippingContactEmailSwitch: UISwitch!
    @IBOutlet var applePayShippingContactPhoneSwitch: UISwitch!
    @IBOutlet var applePayShippingContactPostalAddressSwitch: UISwitch!

    // MARK: Order Inputs

    @IBOutlet var currencyTextField: UITextField!
    @IBOutlet var countryCodeTextField: UITextField!
    @IBOutlet var orderIdTextField: UITextField!
    @IBOutlet var lineItemsStackView: UIStackView!
    @IBOutlet var totalAmountLabel: UILabel!

    // MARK: Customer Inputs

    @IBOutlet var customerIdTextField: UITextField!
    @IBOutlet var customerFirstNameTextField: UITextField!
    @IBOutlet var customerLastNameTextField: UITextField!
    @IBOutlet var customerEmailTextField: UITextField!
    @IBOutlet var customerMobileNumberTextField: UITextField!

    @IBOutlet var billingAddressSwitch: UISwitch!
    @IBOutlet var billingAddressStackView: UIStackView!
    @IBOutlet var billingAddressFirstNameTextField: UITextField!
    @IBOutlet var billingAddressLastNameTextField: UITextField!
    @IBOutlet var billingAddressLine1TextField: UITextField!
    @IBOutlet var billingAddressLine2TextField: UITextField!
    @IBOutlet var billingAddressCityTextField: UITextField!
    @IBOutlet var billingAddressStateTextField: UITextField!
    @IBOutlet var billingAddressPostalCodeTextField: UITextField!
    @IBOutlet var billingAddressCountryTextField: UITextField!

    @IBOutlet var shippingAddressStackView: UIStackView!
    @IBOutlet var shippingAddressSwitch: UISwitch!
    @IBOutlet var shippinAddressFirstNameTextField: UITextField!
    @IBOutlet var shippinAddressLastNameTextField: UITextField!
    @IBOutlet var shippinAddressLine1TextField: UITextField!
    @IBOutlet var shippinAddressLine2TextField: UITextField!
    @IBOutlet var shippinAddressCityTextField: UITextField!
    @IBOutlet var shippinAddressStateTextField: UITextField!
    @IBOutlet var shippinAddressPostalCodeTextField: UITextField!
    @IBOutlet var shippinAddressCountryTextField: UITextField!

    // MARK: Surcharge Inputs

    @IBOutlet var surchargeSwitch: UISwitch!
    @IBOutlet var surchargeStackView: UIStackView!
    @IBOutlet var applePaySurchargeTextField: UITextField!

    @IBOutlet var primerSDKButton: UIButton!
    @IBOutlet var primerHeadlessSDKButton: UIButton!

    var lineItems: [ClientSessionRequestBody.Order.LineItem] {
        get {
            return clientSession.order?.lineItems ?? []
        }
        set {
            clientSession.order?.lineItems = newValue
        }
    }

    let testScenarioPicker = UIPickerView()
    let testFailureFlowPicker = UIPickerView()
    let test3DSScenarioPicker = UIPickerView()

    var renderMode: RenderMode = .createClientSession

    var selectedPaymentHandling: PrimerPaymentHandling = .auto

    var clientSession = MerchantMockDataManager.getClientSession(sessionType: .generic)

    var selectedTestScenario: Test.Scenario?
    var selectedTestFlow: Test.Flow?
    var selectedTest3DSScenario: Test.Params.ThreeDS.Scenario?

    var applyTheme: Bool = false
    var payAfterVaultSuccess: Bool = false

    var applePayCaptureBillingAddress = false
    var applePayBillingAdditionalContactFields: [PrimerApplePayOptions.RequiredContactField]? = []
    var applePayCaptureShippingDetails = false
    var applePayRequireShippingMethod = false
    var applePayShippingAdditionalContactFields: [PrimerApplePayOptions.RequiredContactField]? = []
    var applePayCheckProvidedNetworks = false

    func setAccessibilityIds() {
        view.accessibilityIdentifier = "Background View"
        testingModeSegmentedControl.accessibilityIdentifier = "Testing Mode Segmented Control"
        clientTokenTextField.accessibilityIdentifier = "Client Token Text Field"
    }

    // MARK: - VIEW LIFE-CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()

        setAccessibilityIds()
        testScenarioPicker.dataSource = self
        testScenarioPicker.delegate = self
        testScenarioTextField.inputView = testScenarioPicker

        testFailureFlowPicker.dataSource = self
        testFailureFlowPicker.delegate = self
        testFailureFlowTextField.inputView = testFailureFlowPicker

        test3DSScenarioPicker.dataSource = self
        test3DSScenarioPicker.delegate = self
        test3DSScenarioTextField.inputView = test3DSScenarioPicker

        switch environment {
        case .dev:
            environmentSegmentedControl.selectedSegmentIndex = 0
        case .staging:
            environmentSegmentedControl.selectedSegmentIndex = 1
        case .sandbox:
            environmentSegmentedControl.selectedSegmentIndex = 2
        case .production:
            environmentSegmentedControl.selectedSegmentIndex = 3
        default:
            environmentSegmentedControl.selectedSegmentIndex = 1
        }

        apiKeyTextField.text = customDefinedApiKey

        let viewTap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(viewTap)

        merchantNameTextField.text = "Primer Merchant"
        populateSessionSettingsFields()

        customerIdTextField.addTarget(
            self, action: #selector(customerIdChanged(_:)), for: .editingDidEnd
        )

        handleAppetizeIfNeeded(AppetizeConfigProvider())

        render()

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleAppetizeConfig), name: NSNotification.Name.appetizeURLHandled,
            object: nil
        )
    }

    @objc func handleAppetizeConfig(_ notification: NSNotification) {
        if let payloadProvider = notification.object as? DeeplinkConfigProvider {
            handleAppetizeIfNeeded(AppetizeConfigProvider(payloadProvider: payloadProvider))
        }
    }

    private func handleAppetizeIfNeeded(_ configProvider: AppetizeConfigProvider) {
        if let config = configProvider.fetchConfig() {
            updateUI(for: config)
        }
    }

    @objc func viewTapped() {
        view.endEditing(true)
    }

    func render() {
        switch renderMode {
        case .createClientSession:
            environmentStackView.isHidden = false
            testParamsGroupStackView.isHidden = true
            apiKeyStackView.isHidden = false
            clientTokenStackView.isHidden = true
            sdkSettingsStackView.isHidden = false
            orderStackView.isHidden = false
            customerStackView.isHidden = false
            surchargeGroupStackView.isHidden = false
            klarnaEMDStackView.isHidden = false

        case .clientToken:
            environmentStackView.isHidden = false
            testParamsGroupStackView.isHidden = true
            apiKeyStackView.isHidden = false
            clientTokenStackView.isHidden = false
            sdkSettingsStackView.isHidden = false
            orderStackView.isHidden = true
            customerStackView.isHidden = true
            surchargeGroupStackView.isHidden = true
            klarnaEMDStackView.isHidden = true

        case .testScenario:
            environmentStackView.isHidden = true
            testParamsGroupStackView.isHidden = false
            apiKeyStackView.isHidden = true
            clientTokenStackView.isHidden = true
            sdkSettingsStackView.isHidden = false
            orderStackView.isHidden = false
            customerStackView.isHidden = false
            surchargeGroupStackView.isHidden = false
            klarnaEMDStackView.isHidden = true

            testParamsStackView.isHidden = (selectedTestScenario == nil)

            if testResultSegmentedControl.selectedSegmentIndex == 0 {
                testFailureStackView.isHidden = true
            } else {
                testFailureStackView.isHidden = false
            }

            switch selectedTestScenario {
            case .testNative3DS:
                if testResultSegmentedControl.selectedSegmentIndex == 0 {
                    test3DSStackView.isHidden = false
                } else {
                    test3DSStackView.isHidden = true
                }
            default:
                test3DSStackView.isHidden = true
            }
        }

        gesturesDismissalSwitch.isOn = true // Default value
        closeButtonDismissalSwitch.isOn = false // Default false

        lineItemsStackView.removeAllArrangedSubviews()
        lineItemsStackView.alignment = .fill
        lineItemsStackView.distribution = .fill

        for (index, lineItem) in lineItems.enumerated() {
            let horizontalStackView = UIStackView()
            horizontalStackView.tag = index
            horizontalStackView.axis = .horizontal
            horizontalStackView.alignment = .fill
            horizontalStackView.distribution = .fill

            let nameLbl = UILabel()
            nameLbl.text = (lineItem.description ?? "") + " x\(lineItem.quantity ?? 1)"
            nameLbl.textAlignment = .left
            nameLbl.font = UIFont.systemFont(ofSize: 14)
            horizontalStackView.addArrangedSubview(nameLbl)

            let priceLbl = UILabel()
            priceLbl.text = "\(lineItem.amount ?? 0)"
            priceLbl.textAlignment = .right
            priceLbl.font = UIFont.systemFont(ofSize: 14)
            horizontalStackView.addArrangedSubview(priceLbl)

            let lineItemTapGesture = UITapGestureRecognizer(
                target: self, action: #selector(lineItemTapped)
            )
            horizontalStackView.addGestureRecognizer(lineItemTapGesture)

            lineItemsStackView.addArrangedSubview(horizontalStackView)
        }

        let totalAmount = lineItems.compactMap { ($0.quantity ?? 0) * ($0.amount ?? 0) }.reduce(0, +)
        totalAmountLabel.text = "\(totalAmount)"
    }

    // MARK: - ACTIONS

    @objc func lineItemTapped(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag, lineItems.count > index else {
            return
        }

        let lineItem = lineItems[index]
        let vc = MerchantNewLineItemViewController.instantiate(lineItem: lineItem)
        vc.onLineItemEdited = { lineItem in
            self.lineItems[index] = lineItem
            self.render()
        }
        vc.onLineItemDeleted = { _ in
            self.lineItems.remove(at: index)
            self.render()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func testingModeSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        renderMode = RenderMode(rawValue: sender.selectedSegmentIndex)!
        render()
    }

    @IBAction func apiVersionSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            apiVersion = .V2_3
        case 1:
            apiVersion = .V2_4
        case 2:
            apiVersion = .latest
        default:
            apiVersion = .V2_3
        }
    }

    @IBAction func environmentSegmentedControlValuewChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            environment = .dev
        case 1:
            environment = .staging
        case 2:
            environment = .sandbox
        case 3:
            environment = .production
        default:
            fatalError()
        }
    }

    @IBAction func testResultSegmentedControlValueChanged(_: UISegmentedControl) {
        render()
    }

    @IBAction func checkoutFlowSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedPaymentHandling = .auto
        case 1:
            selectedPaymentHandling = .manual
        default:
            fatalError()
        }
    }

    @IBAction func addLineItemButtonTapped(_: Any) {
        let vc = MerchantNewLineItemViewController.instantiate(lineItem: nil)
        vc.onLineItemAdded = { lineItem in
            self.lineItems.append(lineItem)
            self.render()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func billingAddressSwitchValueChanged(_ sender: UISwitch) {
        billingAddressStackView.isHidden = !sender.isOn
    }

    @IBAction func shippingAddressSwitchValueChanged(_ sender: UISwitch) {
        shippingAddressStackView.isHidden = !sender.isOn
    }

    @IBAction func surchargeSwitchValueChanged(_ sender: UISwitch) {
        surchargeStackView.isHidden = !sender.isOn
    }

    @IBAction func oneTimePaymentValueChanged(_ sender: UISwitch) {
        paymentSessionType = sender.isOn ? .klarnaWithEMD : .generic
        populateSessionSettingsFields()
    }

    @IBAction func applePayCaptureBillingAddressSwitchValueChanged(_ sender: UISwitch) {
        applePayBillingControlStackView.isHidden = !sender.isOn
        applePayCaptureBillingAddress = sender.isOn
    }

    @IBAction func applePayBillingContactNameSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            var fields = applePayBillingAdditionalContactFields ?? []
            if !fields.contains(.name) {
                fields.append(.name)
            }
            applePayBillingAdditionalContactFields = fields
        } else {
            applePayBillingAdditionalContactFields?.removeAll(where: { $0 == .name })
            if applePayBillingAdditionalContactFields?.isEmpty == true {
                applePayBillingAdditionalContactFields = nil
            }
        }
    }

    @IBAction func applePayBillingContactEmailField(_ sender: UISwitch) {
        if sender.isOn {
            var fields = applePayBillingAdditionalContactFields ?? []
            if !fields.contains(.emailAddress) {
                fields.append(.emailAddress)
            }
            applePayBillingAdditionalContactFields = fields
        } else {
            applePayBillingAdditionalContactFields?.removeAll(where: { $0 == .emailAddress })
            if applePayBillingAdditionalContactFields?.isEmpty == true {
                applePayBillingAdditionalContactFields = nil
            }
        }
    }

    @IBAction func applePayBillingContactPhoneSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            var fields = applePayBillingAdditionalContactFields ?? []
            if !fields.contains(.phoneNumber) {
                fields.append(.phoneNumber)
            }
            applePayBillingAdditionalContactFields = fields
        } else {
            applePayBillingAdditionalContactFields?.removeAll(where: { $0 == .phoneNumber })
            if applePayBillingAdditionalContactFields?.isEmpty == true {
                applePayBillingAdditionalContactFields = nil
            }
        }
    }

    @IBAction func applePayBillingContactPostalAddressSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            var fields = applePayBillingAdditionalContactFields ?? []
            if !fields.contains(.postalAddress) {
                fields.append(.postalAddress)
            }
            applePayBillingAdditionalContactFields = fields
        } else {
            applePayBillingAdditionalContactFields?.removeAll(where: { $0 == .postalAddress })
            if applePayBillingAdditionalContactFields?.isEmpty == true {
                applePayBillingAdditionalContactFields = nil
            }
        }
    }

    @IBAction func applePayCaptureShippingDetailsSwitchChanged(_ sender: UISwitch) {
        applePayShippingControlStackView.isHidden = !sender.isOn
        applePayCaptureShippingDetails = sender.isOn
    }

    @IBAction func applePayRequireShippingMethodSwitchChanged(_ sender: UISwitch) {
        applePayRequireShippingMethod = sender.isOn
    }

    @IBAction func applePayShippingContactNameSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            var fields = applePayShippingAdditionalContactFields ?? []
            if !fields.contains(.name) {
                fields.append(.name)
            }
            applePayShippingAdditionalContactFields = fields
        } else {
            applePayShippingAdditionalContactFields?.removeAll(where: { $0 == .name })
            if applePayShippingAdditionalContactFields?.isEmpty == true {
                applePayShippingAdditionalContactFields = nil
            }
        }
    }

    @IBAction func applePayShippingContactEmailField(_ sender: UISwitch) {
        if sender.isOn {
            var fields = applePayShippingAdditionalContactFields ?? []
            if !fields.contains(.emailAddress) {
                fields.append(.emailAddress)
            }
            applePayShippingAdditionalContactFields = fields
        } else {
            applePayShippingAdditionalContactFields?.removeAll(where: { $0 == .emailAddress })
            if applePayShippingAdditionalContactFields?.isEmpty == true {
                applePayShippingAdditionalContactFields = nil
            }
        }
    }

    @IBAction func applePayShippingContactPhoneSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            var fields = applePayShippingAdditionalContactFields ?? []
            if !fields.contains(.phoneNumber) {
                fields.append(.phoneNumber)
            }
            applePayShippingAdditionalContactFields = fields
        } else {
            applePayShippingAdditionalContactFields?.removeAll(where: { $0 == .phoneNumber })
            if applePayShippingAdditionalContactFields?.isEmpty == true {
                applePayShippingAdditionalContactFields = nil
            }
        }
    }

    @IBAction func applePayShippingContactPostalAddressSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            var fields = applePayShippingAdditionalContactFields ?? []
            if !fields.contains(.postalAddress) {
                fields.append(.postalAddress)
            }
            applePayShippingAdditionalContactFields = fields
        } else {
            applePayShippingAdditionalContactFields?.removeAll(where: { $0 == .postalAddress })
            if applePayShippingAdditionalContactFields?.isEmpty == true {
                applePayShippingAdditionalContactFields = nil
            }
        }
    }

    @IBAction func applePayCheckProvidedNetworksSwitchValueChanged(_ sender: UISwitch) {
        applePayCheckProvidedNetworks = sender.isOn
    }

    func configureClientSession() {
        clientSession.currencyCode = CurrencyLoader().getCurrency(currencyTextField.text ?? "")?.code
        clientSession.order?.countryCode = CountryCode(rawValue: countryCodeTextField.text ?? "")
        clientSession.orderId = orderIdTextField.text
        clientSession.customerId = customerIdTextField.text
        clientSession.customer?.firstName = customerFirstNameTextField.text
        clientSession.customer?.lastName = customerLastNameTextField.text
        clientSession.customer?.emailAddress = customerEmailTextField.text
        clientSession.customer?.mobileNumber = customerMobileNumberTextField.text

        if billingAddressSwitch.isOn {
            clientSession.customer?.billingAddress?.firstName = billingAddressFirstNameTextField.text
            clientSession.customer?.billingAddress?.lastName = billingAddressLastNameTextField.text
            clientSession.customer?.billingAddress?.addressLine1 = billingAddressLine1TextField.text
            clientSession.customer?.billingAddress?.addressLine2 = billingAddressLine2TextField.text
            clientSession.customer?.billingAddress?.city = billingAddressCityTextField.text
            clientSession.customer?.billingAddress?.state = billingAddressStateTextField.text
            clientSession.customer?.billingAddress?.postalCode = billingAddressPostalCodeTextField.text
            clientSession.customer?.billingAddress?.countryCode = billingAddressCountryTextField.text
        } else {
            clientSession.customer?.billingAddress = nil
        }

        if shippingAddressSwitch.isOn {
            clientSession.customer?.shippingAddress?.firstName = shippinAddressFirstNameTextField.text
            clientSession.customer?.shippingAddress?.lastName = shippinAddressLastNameTextField.text
            clientSession.customer?.shippingAddress?.addressLine1 = shippinAddressLine1TextField.text
            clientSession.customer?.shippingAddress?.addressLine2 = shippinAddressLine2TextField.text
            clientSession.customer?.shippingAddress?.city = shippinAddressCityTextField.text
            clientSession.customer?.shippingAddress?.state = shippinAddressStateTextField.text
            clientSession.customer?.shippingAddress?.postalCode = shippinAddressPostalCodeTextField.text
            clientSession.customer?.shippingAddress?.countryCode = shippinAddressCountryTextField.text
        } else {
            clientSession.customer?.shippingAddress = nil
        }

        clientSession.paymentMethod = MerchantMockDataManager.getPaymentMethod(
            sessionType: paymentSessionType)
        if paymentSessionType == .generic && enableCVVRecaptureFlowSwitch.isOn {
            let option = ClientSessionRequestBody.PaymentMethod.PaymentMethodOption(
                surcharge: nil,
                instalmentDuration: nil,
                extraMerchantData: nil,
                captureVaultedCardCvv: enableCVVRecaptureFlowSwitch.isOn,
                merchantName: nil
            )

            clientSession.paymentMethod?.options?.PAYMENT_CARD = option
        }

        let applePayOptions = ClientSessionRequestBody.PaymentMethod.PaymentMethodOption(
            surcharge: nil,
            instalmentDuration: nil,
            extraMerchantData: nil,
            captureVaultedCardCvv: nil,
            merchantName: "Primer Merchant iOS"
        )

        clientSession.paymentMethod?.options?.APPLE_PAY = applePayOptions

        if vaultingFlowSegmentedControl.selectedSegmentIndex == 1 {
            clientSession.paymentMethod?.vaultOnSuccess = true
            clientSession.paymentMethod?.vaultOnAgreement = nil
        } else if vaultingFlowSegmentedControl.selectedSegmentIndex == 2 {
            clientSession.paymentMethod?.vaultOnAgreement = true
            clientSession.paymentMethod?.vaultOnSuccess = nil
        } else {
            clientSession.paymentMethod?.vaultOnSuccess = nil
            clientSession.paymentMethod?.vaultOnAgreement = nil
        }

        clientSession.metadata = .dictionary([
            "deviceInfo": .dictionary([
                "ipAddress": .string("127.0.0.1"),
                "userAgent": .string("iOS"),
            ]),
        ])

        if let metadata = metadataTextField.text, !metadata.isEmpty, var metadataDict = clientSession.metadata {
            metadataTextField.text?.components(separatedBy: ",").forEach {
                let tuple = String($0).components(separatedBy: "=")
                guard tuple.count == 2
                else { return }
                let key = tuple[0].trimmingCharacters(in: .whitespaces)
                let value = tuple[1].trimmingCharacters(in: .whitespaces)
                try? metadataDict.add(.string(value), forKey: key)
            }
            clientSession.metadata = metadataDict
        }
    }

    func populateSessionSettingsFields() {
        clientSession = MerchantMockDataManager.getClientSession(sessionType: paymentSessionType)

        enableCVVRecaptureFlowSwitch.isOn =
            clientSession.paymentMethod?.options?.PAYMENT_CARD?.captureVaultedCardCvv == true

        currencyTextField.text = clientSession.currencyCode
        countryCodeTextField.text = clientSession.order?.countryCode?.rawValue
        orderIdTextField.text = clientSession.orderId

        customerIdTextField.text = clientSession.customerId
        customerFirstNameTextField.text = clientSession.customer?.firstName
        customerLastNameTextField.text = clientSession.customer?.lastName
        customerEmailTextField.text = clientSession.customer?.emailAddress
        customerMobileNumberTextField.text = clientSession.customer?.mobileNumber

        billingAddressSwitch.isOn = true
        billingAddressFirstNameTextField.text = clientSession.customer?.billingAddress?.firstName
        billingAddressLastNameTextField.text = clientSession.customer?.billingAddress?.lastName
        billingAddressLine1TextField.text = clientSession.customer?.billingAddress?.addressLine1
        billingAddressLine2TextField.text = clientSession.customer?.billingAddress?.addressLine2
        billingAddressCityTextField.text = clientSession.customer?.billingAddress?.city
        billingAddressStateTextField.text = clientSession.customer?.billingAddress?.state
        billingAddressPostalCodeTextField.text = clientSession.customer?.billingAddress?.postalCode
        billingAddressCountryTextField.text = clientSession.customer?.billingAddress?.countryCode

        shippingAddressSwitch.isOn = true
        shippinAddressFirstNameTextField.text = clientSession.customer?.shippingAddress?.firstName
        shippinAddressLastNameTextField.text = clientSession.customer?.shippingAddress?.lastName
        shippinAddressLine1TextField.text = clientSession.customer?.shippingAddress?.addressLine1
        shippinAddressLine2TextField.text = clientSession.customer?.shippingAddress?.addressLine2
        shippinAddressCityTextField.text = clientSession.customer?.shippingAddress?.city
        shippinAddressStateTextField.text = clientSession.customer?.shippingAddress?.state
        shippinAddressPostalCodeTextField.text = clientSession.customer?.shippingAddress?.postalCode
        shippinAddressCountryTextField.text = clientSession.customer?.shippingAddress?.countryCode
    }

    func configureTestScenario() {
        guard let selectedTestScenario = selectedTestScenario else {
            let alert = UIAlertController(
                title: "Error", message: "Please choose Test Scenario", preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        var testParams = Test.Params(
            scenario: selectedTestScenario,
            result: .success,
            network: nil,
            polling: nil,
            threeDS: nil
        )

        if testResultSegmentedControl.selectedSegmentIndex == 1 {
            guard let selectedTestFlow = selectedTestFlow else {
                let alert = UIAlertController(
                    title: "Error", message: "Please choose failure flow in the Failure Parameters",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }

            let failure = Test.Params.Failure(
                flow: selectedTestFlow,
                error: Test.Params.Failure.Error(
                    errorId: testErrorIdTextField.text ?? "test-error-id",
                    description: testErrorDescriptionTextField.text ?? "test-error-description"
                )
            )

            testParams.result = .failure(failure: failure)

        } else if case .testNative3DS = selectedTestScenario {
            guard let selectedTest3DSScenario = selectedTest3DSScenario else {
                let alert = UIAlertController(
                    title: "Error", message: "Please choose 3DS scenario", preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            testParams.threeDS = Test.Params.ThreeDS(scenario: selectedTest3DSScenario)
        }

        clientSession.testParams = testParams
    }

    @IBAction func primerSDKButtonTapped(_: Any) {
        customDefinedApiKey = (apiKeyTextField.text ?? "").isEmpty ? nil : apiKeyTextField.text

        let selectedDismissalMechanisms: [DismissalMechanism] = {
            var mechanisms = [DismissalMechanism]()
            if gesturesDismissalSwitch.isOn {
                mechanisms.append(.gestures)
            }
            if closeButtonDismissalSwitch.isOn {
                mechanisms.append(.closeButton)
            }
            return mechanisms
        }()

        let uiOptions = PrimerUIOptions(
            isInitScreenEnabled: !disableInitScreenSwitch.isOn,
            isSuccessScreenEnabled: !disableSuccessScreenSwitch.isOn,
            isErrorScreenEnabled: !disableErrorScreenSwitch.isOn,
            dismissalMechanism: selectedDismissalMechanisms,
            theme: applyThemingSwitch.isOn ? CheckoutTheme.tropical : nil
        )

        let mandateData = PrimerStripeOptions.MandateData.templateMandate(merchantName: "Primer Inc.")

        let shippingOptions = applePayCaptureShippingDetails ?
            PrimerApplePayOptions.ShippingOptions(shippingContactFields: applePayShippingAdditionalContactFields,
                                                  requireShippingMethod: applePayRequireShippingMethod) : nil

        let billingOptions = applePayCaptureBillingAddress ?
            PrimerApplePayOptions.BillingOptions(requiredBillingContactFields: applePayBillingAdditionalContactFields) : nil

        let stripePublishableKey = SecretsManager.shared.value(forKey: .stripePublishableKey)

        let settings = PrimerSettings(
            paymentHandling: selectedPaymentHandling,
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "merchant://primer.io",
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: "merchant.checkout.team",
                    merchantName: merchantNameTextField.text ?? "Primer Merchant",
                    isCaptureBillingAddressEnabled: applePayCaptureBillingAddress,
                    showApplePayForUnsupportedDevice: false,
                    checkProvidedNetworks: applePayCheckProvidedNetworks,
                    shippingOptions: shippingOptions,
                    billingOptions: billingOptions
                ),
                stripeOptions: stripePublishableKey == nil ? nil : PrimerStripeOptions(publishableKey: stripePublishableKey!, mandateData: mandateData)
            ),
            uiOptions: uiOptions,
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false),
            apiVersion: apiVersion
        )

        switch renderMode {
        case .createClientSession, .testScenario:
            configureClientSession()
            if case .testScenario = renderMode {
                configureTestScenario()
            }
            let vc = MerchantDropInUIViewController.instantiate(
                settings: settings, clientSession: clientSession, clientToken: nil
            )
            navigationController?.pushViewController(vc, animated: true)

        case .clientToken:
            let vc = MerchantDropInUIViewController.instantiate(
                settings: settings, clientSession: nil, clientToken: clientTokenTextField.text
            )
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func primerHeadlessButtonTapped(_: Any) {
        customDefinedApiKey = (apiKeyTextField.text ?? "").isEmpty ? nil : apiKeyTextField.text

        let shippingOptions = applePayCaptureShippingDetails ?
            PrimerApplePayOptions.ShippingOptions(shippingContactFields: applePayShippingAdditionalContactFields,
                                                  requireShippingMethod: applePayRequireShippingMethod) : nil

        let billingOptions = applePayCaptureBillingAddress ?
            PrimerApplePayOptions.BillingOptions(requiredBillingContactFields: applePayBillingAdditionalContactFields) : nil

        let stripePublishableKey = SecretsManager.shared.value(forKey: .stripePublishableKey)

        let settings = PrimerSettings(
            paymentHandling: selectedPaymentHandling,
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "merchant://primer.io",
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: "merchant.checkout.team",
                    merchantName: merchantNameTextField.text ?? "Primer Merchant",
                    isCaptureBillingAddressEnabled: applePayCaptureBillingAddress,
                    showApplePayForUnsupportedDevice: false,
                    checkProvidedNetworks: applePayCheckProvidedNetworks,
                    shippingOptions: shippingOptions,
                    billingOptions: billingOptions
                ),
                stripeOptions: stripePublishableKey == nil ? nil : PrimerStripeOptions(publishableKey: stripePublishableKey!)
            ),
            uiOptions: nil,
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false),
            apiVersion: apiVersion
        )

        switch renderMode {
        case .createClientSession, .testScenario:
            configureClientSession()
            if case .testScenario = renderMode {
                configureTestScenario()
            }
            let vc = MerchantHeadlessCheckoutAvailablePaymentMethodsViewController.instantiate(
                settings: settings,
                clientSession: clientSession,
                clientToken: nil
            )
            navigationController?.pushViewController(vc, animated: true)
        case .clientToken:
            let vc = MerchantHeadlessCheckoutAvailablePaymentMethodsViewController.instantiate(
                settings: settings,
                clientSession: nil,
                clientToken: clientTokenTextField.text
            )
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func customerIdChanged(_: UITextField!) {
        guard let text = customerIdTextField.text else { return }
        UserDefaults.standard.set(text, forKey: MerchantMockDataManager.customerIdStorageKey)
    }
}

extension MerchantSessionAndSettingsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in _: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        if pickerView == testScenarioPicker {
            return Test.Scenario.allCases.count + 1
        } else if pickerView == testFailureFlowPicker {
            return Test.Flow.allCases.count + 1
        } else if pickerView == test3DSScenarioPicker {
            return Test.Params.ThreeDS.Scenario.allCases.count + 1
        }

        return 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent _: Int)
        -> String?
    {
        if row == 0 {
            return "-"
        } else {
            if pickerView == testScenarioPicker {
                return Test.Scenario.allCases[row - 1].rawValue
            } else if pickerView == testFailureFlowPicker {
                return Test.Flow.allCases[row - 1].rawValue
            } else if pickerView == test3DSScenarioPicker {
                return Test.Params.ThreeDS.Scenario.allCases[row - 1].rawValue
            }
        }

        return nil
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        if pickerView == testScenarioPicker {
            if row == 0 {
                selectedTestScenario = nil
                testScenarioTextField.text = "-"
            } else {
                selectedTestScenario = Test.Scenario.allCases[row - 1]
                testScenarioTextField.text = selectedTestScenario?.rawValue
            }
        } else if pickerView == testFailureFlowPicker {
            if row == 0 {
                selectedTestFlow = nil
                testFailureFlowTextField.text = "-"
            } else {
                selectedTestFlow = Test.Flow.allCases[row - 1]
                testFailureFlowTextField.text = selectedTestFlow?.rawValue
            }
        } else if pickerView == test3DSScenarioPicker {
            if row == 0 {
                selectedTest3DSScenario = nil
                test3DSScenarioTextField.text = "-"
            } else {
                selectedTest3DSScenario = Test.Params.ThreeDS.Scenario.allCases[row - 1]
                test3DSScenarioTextField.text = selectedTest3DSScenario?.rawValue
            }
        }

        render()
    }
}

extension MerchantSessionAndSettingsViewController {
    private func updateUI(for config: SessionConfiguration) {
        apiKeyTextField.text = config.customApiKey
        customerIdTextField.text = config.customerId.isEmpty ? "ios-customer-id" : config.customerId

        switch config.env {
        case .dev:
            environmentSegmentedControl.selectedSegmentIndex = 0
        case .sandbox:
            environmentSegmentedControl.selectedSegmentIndex = 2
        case .staging:
            environmentSegmentedControl.selectedSegmentIndex = 1
        case .production:
            environmentSegmentedControl.selectedSegmentIndex = 3
        case .local:
            environmentSegmentedControl.selectedSegmentIndex = 2
        }
        environment = config.env

        switch config.paymentHandling {
        case .auto:
            checkoutFlowSegmentedControl.selectedSegmentIndex = 0
        case .manual:
            checkoutFlowSegmentedControl.selectedSegmentIndex = 1
        }

        currencyTextField.text = config.currency
        countryCodeTextField.text = config.countryCode

        let lineItem = ClientSessionRequestBody.Order.LineItem(
            itemId: "ld-lineitem",
            description: "Fancy Shoes",
            amount: Int(config.value) ?? 100,
            quantity: 1,
            discountAmount: nil,
            taxAmount: nil
        )

        lineItems = [lineItem]

        metadataTextField.text = config.metadata
    }
}
