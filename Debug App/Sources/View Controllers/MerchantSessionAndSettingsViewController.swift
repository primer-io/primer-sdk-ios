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
var customDefinedApiKey: String?
var performPaymentAfterVaulting: Bool = false
var useNewWorkflows = true
var paymentSessionType: MerchantMockDataManager.SessionType = .generic

class MerchantSessionAndSettingsViewController: UIViewController {

    enum RenderMode: Int {
        case createClientSession = 0
        case clientToken
        case testScenario
    }

    // MARK: Stack Views

    @IBOutlet weak var environmentStackView: UIStackView!
    @IBOutlet weak var testParamsGroupStackView: UIStackView!
    @IBOutlet weak var apiKeyStackView: UIStackView!
    @IBOutlet weak var useNewWorkflowsStackView: UIStackView!
    @IBOutlet weak var klarnaEMDStackView: UIStackView!
    @IBOutlet weak var clientTokenStackView: UIStackView!
    @IBOutlet weak var sdkSettingsStackView: UIStackView!
    @IBOutlet weak var orderStackView: UIStackView!
    @IBOutlet weak var customerStackView: UIStackView!
    @IBOutlet weak var surchargeGroupStackView: UIStackView!

    // MARK: Testing Mode Inputs

    @IBOutlet weak var testingModeSegmentedControl: UISegmentedControl!

    // MARK: Environment Inputs

    @IBOutlet weak var environmentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var clientTokenTextField: UITextField!
    @IBOutlet weak var metadataTextField: UITextField!

    // MARK: Test Inputs

    @IBOutlet weak var testScenarioTextField: UITextField!
    @IBOutlet weak var testResultSegmentedControl: UISegmentedControl!
    @IBOutlet weak var testParamsStackView: UIStackView!
    @IBOutlet weak var testResultStackView: UIStackView!
    @IBOutlet weak var testFailureStackView: UIStackView!
    @IBOutlet weak var testFailureFlowTextField: UITextField!
    @IBOutlet weak var testErrorIdTextField: UITextField!
    @IBOutlet weak var testErrorDescriptionTextField: UITextField!
    @IBOutlet weak var test3DSStackView: UIStackView!
    @IBOutlet weak var test3DSScenarioTextField: UITextField!

    // MARK: SDK Settings Inputs
    @IBOutlet weak var useNewWorkflowsSwitch: UISwitch!
    @IBOutlet weak var checkoutFlowSegmentedControl: UISegmentedControl!
    @IBOutlet weak var merchantNameTextField: UITextField!
    @IBOutlet weak var applyThemingSwitch: UISwitch!
    @IBOutlet weak var vaultPaymentsSwitch: UISwitch!
    @IBOutlet weak var disableSuccessScreenSwitch: UISwitch!
    @IBOutlet weak var disableErrorScreenSwitch: UISwitch!
    @IBOutlet weak var disableInitScreenSwitch: UISwitch!
    @IBOutlet weak var enableCVVRecaptureFlowSwitch: UISwitch!

    // MARK: Order Inputs

    @IBOutlet weak var currencyTextField: UITextField!
    @IBOutlet weak var countryCodeTextField: UITextField!
    @IBOutlet weak var orderIdTextField: UITextField!
    @IBOutlet weak var lineItemsStackView: UIStackView!
    @IBOutlet weak var totalAmountLabel: UILabel!

    // MARK: Customer Inputs

    @IBOutlet weak var customerIdTextField: UITextField!
    @IBOutlet weak var customerFirstNameTextField: UITextField!
    @IBOutlet weak var customerLastNameTextField: UITextField!
    @IBOutlet weak var customerEmailTextField: UITextField!
    @IBOutlet weak var customerMobileNumberTextField: UITextField!

    @IBOutlet weak var billingAddressSwitch: UISwitch!
    @IBOutlet weak var billingAddressStackView: UIStackView!
    @IBOutlet weak var billingAddressFirstNameTextField: UITextField!
    @IBOutlet weak var billingAddressLastNameTextField: UITextField!
    @IBOutlet weak var billingAddressLine1TextField: UITextField!
    @IBOutlet weak var billingAddressLine2TextField: UITextField!
    @IBOutlet weak var billingAddressCityTextField: UITextField!
    @IBOutlet weak var billingAddressStateTextField: UITextField!
    @IBOutlet weak var billingAddressPostalCodeTextField: UITextField!
    @IBOutlet weak var billingAddressCountryTextField: UITextField!

    @IBOutlet weak var shippingAddressStackView: UIStackView!
    @IBOutlet weak var shippingAddressSwitch: UISwitch!
    @IBOutlet weak var shippinAddressFirstNameTextField: UITextField!
    @IBOutlet weak var shippinAddressLastNameTextField: UITextField!
    @IBOutlet weak var shippinAddressLine1TextField: UITextField!
    @IBOutlet weak var shippinAddressLine2TextField: UITextField!
    @IBOutlet weak var shippinAddressCityTextField: UITextField!
    @IBOutlet weak var shippinAddressStateTextField: UITextField!
    @IBOutlet weak var shippinAddressPostalCodeTextField: UITextField!
    @IBOutlet weak var shippinAddressCountryTextField: UITextField!

    // MARK: Surcharge Inputs

    @IBOutlet weak var surchargeSwitch: UISwitch!
    @IBOutlet weak var surchargeStackView: UIStackView!
    @IBOutlet weak var applePaySurchargeTextField: UITextField!

    @IBOutlet weak var primerSDKButton: UIButton!
    @IBOutlet weak var primerHeadlessSDKButton: UIButton!

    var lineItems: [ClientSessionRequestBody.Order.LineItem] {
        get {
            return self.clientSession.order?.lineItems ?? []
        }
        set {
            self.clientSession.order?.lineItems = newValue
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

    func setAccessibilityIds() {
        self.view.accessibilityIdentifier = "Background View"
        self.testingModeSegmentedControl.accessibilityIdentifier = "Testing Mode Segmented Control"
        self.clientTokenTextField.accessibilityIdentifier = "Client Token Text Field"
    }

    // MARK: - VIEW LIFE-CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setAccessibilityIds()
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

        self.apiKeyTextField.text = customDefinedApiKey

        let viewTap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(viewTap)

        merchantNameTextField.text = "Primer Merchant"
        populateSessionSettingsFields()

        customerIdTextField.addTarget(self, action: #selector(customerIdChanged(_:)), for: .editingDidEnd)

        handleAppetizeIfNeeded(AppetizeConfigProvider())

        render()

        NotificationCenter.default.addObserver(self, selector: #selector(handleAppetizeConfig), name: NSNotification.Name.appetizeURLHandled, object: nil)
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
            useNewWorkflowsStackView.isHidden = false
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
            useNewWorkflowsStackView.isHidden = true
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
            useNewWorkflowsStackView.isHidden = true
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

            let lineItemTapGesture = UITapGestureRecognizer(target: self, action: #selector(lineItemTapped))
            horizontalStackView.addGestureRecognizer(lineItemTapGesture)

            lineItemsStackView.addArrangedSubview(horizontalStackView)
        }

        let totalAmount = lineItems.compactMap({ (($0.quantity ?? 0) * ($0.amount ?? 0)) }).reduce(0, +)
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

    @IBAction func testResultSegmentedControlValueChanged(_ sender: UISegmentedControl) {
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

    @IBAction func addLineItemButtonTapped(_ sender: Any) {
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

    @IBAction func useNewWorkflowsSwitchValueChanged(_ sender: UISwitch) {
        useNewWorkflows = sender.isOn
    }

    @IBAction func oneTimePaymentValueChanged(_ sender: UISwitch) {
        paymentSessionType = sender.isOn ? .klarnaWithEMD : .generic
        populateSessionSettingsFields()
    }

    func configureClientSession() {
        clientSession.currencyCode = CurrencyLoader().getCurrency(currencyTextField.text ?? "")
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

        clientSession.paymentMethod = MerchantMockDataManager.getPaymentMethod(sessionType: paymentSessionType)
        if paymentSessionType == .generic && enableCVVRecaptureFlowSwitch.isOn {
            let option = ClientSessionRequestBody.PaymentMethod.PaymentMethodOption(surcharge: nil,
                                                                                    instalmentDuration: nil,
                                                                                    extraMerchantData: nil,
                                                                                    captureVaultedCardCvv: enableCVVRecaptureFlowSwitch.isOn)

            let optionGroup = ClientSessionRequestBody.PaymentMethod.PaymentMethodOptionGroup(PAYMENT_CARD: option)
            clientSession.paymentMethod?.options = optionGroup
        }
        if let metadata = metadataTextField.text, !metadata.isEmpty {
            clientSession.metadata = MetadataParser().parse(metadata)
        }
    }

    func populateSessionSettingsFields() {
        clientSession = MerchantMockDataManager.getClientSession(sessionType: paymentSessionType)

        enableCVVRecaptureFlowSwitch.isOn = clientSession.paymentMethod?.options?.PAYMENT_CARD?.captureVaultedCardCvv ?? false

        currencyTextField.text = clientSession.currencyCode?.code
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
            let alert = UIAlertController(title: "Error", message: "Please choose Test Scenario", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        var testParams = Test.Params(
            scenario: selectedTestScenario,
            result: .success,
            network: nil,
            polling: nil,
            threeDS: nil)

        if testResultSegmentedControl.selectedSegmentIndex == 1 {
            guard let selectedTestFlow = selectedTestFlow else {
                let alert = UIAlertController(title: "Error", message: "Please choose failure flow in the Failure Parameters", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }

            let failure = Test.Params.Failure(
                flow: selectedTestFlow,
                error: Test.Params.Failure.Error(
                    errorId: testErrorIdTextField.text ?? "test-error-id",
                    description: testErrorDescriptionTextField.text ?? "test-error-description"))

            testParams.result = .failure(failure: failure)

        } else if case .testNative3DS = selectedTestScenario {
            guard let selectedTest3DSScenario = selectedTest3DSScenario else {
                let alert = UIAlertController(title: "Error", message: "Please choose 3DS scenario", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            testParams.threeDS = Test.Params.ThreeDS(scenario: selectedTest3DSScenario)
        }

        clientSession.testParams = testParams
    }

    @IBAction func primerSDKButtonTapped(_ sender: Any) {
        customDefinedApiKey = (apiKeyTextField.text ?? "").isEmpty ? nil : apiKeyTextField.text

        let uiOptions = PrimerUIOptions(
            isInitScreenEnabled: !disableInitScreenSwitch.isOn,
            isSuccessScreenEnabled: !disableSuccessScreenSwitch.isOn,
            isErrorScreenEnabled: !disableErrorScreenSwitch.isOn,
            theme: applyThemingSwitch.isOn ? CheckoutTheme.tropical : nil)

        let settings = PrimerSettings(
            paymentHandling: selectedPaymentHandling,
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "merchant://primer.io",
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: "merchant.checkout.team",
                    merchantName: merchantNameTextField.text ?? "Primer Merchant",
                    isCaptureBillingAddressEnabled: false,
                    showApplePayForUnsupportedDevice: false,
                    checkProvidedNetworks: false)),
            uiOptions: uiOptions,
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
        )

        switch renderMode {
        case .createClientSession, .testScenario:
            configureClientSession()
            if case .testScenario = renderMode {
                configureTestScenario()
            }
            let vc = MerchantDropInUIViewController.instantiate(settings: settings, clientSession: clientSession, clientToken: nil)
            navigationController?.pushViewController(vc, animated: true)

        case .clientToken:
            let vc = MerchantDropInUIViewController.instantiate(settings: settings, clientSession: nil, clientToken: clientTokenTextField.text)
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func primerHeadlessButtonTapped(_ sender: Any) {
        customDefinedApiKey = (apiKeyTextField.text ?? "").isEmpty ? nil : apiKeyTextField.text

        let settings = PrimerSettings(
            paymentHandling: selectedPaymentHandling,
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "merchant://primer.io",
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: "merchant.checkout.team",
                    merchantName: merchantNameTextField.text ?? "Primer Merchant",
                    isCaptureBillingAddressEnabled: false,
                    showApplePayForUnsupportedDevice: false,
                    checkProvidedNetworks: false)),
            uiOptions: nil,
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
        )

        switch renderMode {
        case .createClientSession, .testScenario:
            configureClientSession()
            if case .testScenario = renderMode {
                configureTestScenario()
            }
            let vc = MerchantHeadlessCheckoutAvailablePaymentMethodsViewController.instantiate(settings: settings,
                                                                                               clientSession: clientSession,
                                                                                               clientToken: nil)
            navigationController?.pushViewController(vc, animated: true)
        case .clientToken:
            let vc = MerchantHeadlessCheckoutAvailablePaymentMethodsViewController.instantiate(settings: settings,
                                                                                               clientSession: nil,
                                                                                               clientToken: clientTokenTextField.text)
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func customerIdChanged(_ textField: UITextField!) {
        guard let text = customerIdTextField.text else { return }
        UserDefaults.standard.set(text, forKey: MerchantMockDataManager.customerIdStorageKey)
    }
}

extension MerchantSessionAndSettingsViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == testScenarioPicker {
            return Test.Scenario.allCases.count + 1
        } else if pickerView == testFailureFlowPicker {
            return Test.Flow.allCases.count + 1
        } else if pickerView == test3DSScenarioPicker {
            return Test.Params.ThreeDS.Scenario.allCases.count + 1
        }

        return 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "-"
        } else {
            if pickerView == testScenarioPicker {
                return Test.Scenario.allCases[row-1].rawValue
            } else if pickerView == testFailureFlowPicker {
                return Test.Flow.allCases[row-1].rawValue
            } else if pickerView == test3DSScenarioPicker {
                return Test.Params.ThreeDS.Scenario.allCases[row-1].rawValue
            }
        }

        return nil
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == testScenarioPicker {
            if row == 0 {
                selectedTestScenario = nil
                testScenarioTextField.text = "-"
            } else {
                selectedTestScenario = Test.Scenario.allCases[row-1]
                testScenarioTextField.text = selectedTestScenario?.rawValue
            }
        } else if pickerView == testFailureFlowPicker {
            if row == 0 {
                selectedTestFlow = nil
                testFailureFlowTextField.text = "-"
            } else {
                selectedTestFlow = Test.Flow.allCases[row-1]
                testFailureFlowTextField.text = selectedTestFlow?.rawValue
            }
        } else if pickerView == test3DSScenarioPicker {
            if row == 0 {
                selectedTest3DSScenario = nil
                test3DSScenarioTextField.text = "-"
            } else {
                selectedTest3DSScenario = Test.Params.ThreeDS.Scenario.allCases[row-1]
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

        let lineItem = ClientSessionRequestBody.Order.LineItem(itemId: "ld-lineitem",
                                                               description: "Fancy Shoes",
                                                               amount: Int(config.value) ?? 100,
                                                               quantity: 1,
                                                               discountAmount: nil,
                                                               taxAmount: nil)

        self.lineItems = [lineItem]

        metadataTextField.text = config.metadata
        useNewWorkflows = config.newWorkflows
        useNewWorkflowsSwitch.isOn = config.newWorkflows
    }
}
