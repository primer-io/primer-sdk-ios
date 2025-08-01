//
//  MerchantSessionAndSettingsViewController.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
        case deepLink
    }

    // MARK: Stack Views

    @IBOutlet weak var environmentStackView: UIStackView!
    @IBOutlet weak var testParamsGroupStackView: UIStackView!
    @IBOutlet weak var apiKeyStackView: UIStackView!
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
    @IBOutlet weak var checkoutFlowSegmentedControl: UISegmentedControl!
    @IBOutlet weak var vaultingFlowSegmentedControl: UISegmentedControl!
    @IBOutlet weak var merchantNameTextField: UITextField!
    @IBOutlet weak var applyThemingSwitch: UISwitch!
    @IBOutlet weak var disableSuccessScreenSwitch: UISwitch!
    @IBOutlet weak var disableErrorScreenSwitch: UISwitch!
    @IBOutlet weak var gesturesDismissalSwitch: UISwitch!
    @IBOutlet weak var closeButtonDismissalSwitch: UISwitch!
    @IBOutlet weak var disableInitScreenSwitch: UISwitch!
    @IBOutlet weak var enableCVVRecaptureFlowSwitch: UISwitch!
    @IBOutlet weak var addNewCardSwitch: UISwitch!


    // MARK: Apple Pay Inputs
    @IBOutlet weak var applePayCaptureBillingAddressSwitch: UISwitch!
    @IBOutlet weak var applePayCheckProvidedNetworksSwitch: UISwitch!

    @IBOutlet weak var applePayBillingControlStackView: UIStackView!
    @IBOutlet weak var applePayBillingContactNameSwitch: UISwitch!
    @IBOutlet weak var applePayBillingContactEmailSwitch: UISwitch!
    @IBOutlet weak var applePayBillingContactPhoneSwitch: UISwitch!
    @IBOutlet weak var applePayBillingContactPostalAddressSwitch: UISwitch!

    @IBOutlet weak var applePayShippingControlStackView: UIStackView!
    @IBOutlet weak var applePayShippingDetailsSwitch: UISwitch!
    @IBOutlet weak var applePayRequireShippingMethodSwitch: UISwitch!
    @IBOutlet weak var applePayShippingContactNameSwitch: UISwitch!
    @IBOutlet weak var applePayShippingContactEmailSwitch: UISwitch!
    @IBOutlet weak var applePayShippingContactPhoneSwitch: UISwitch!
    @IBOutlet weak var applePayShippingContactPostalAddressSwitch: UISwitch!

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
    @IBOutlet weak var surchargeTextField: UITextField!
    @IBOutlet weak var primerSDKButton: UIButton!
    @IBOutlet weak var primerHeadlessSDKButton: UIButton!

    @IBOutlet weak var deepLinkStackView: UIStackView!
    @IBOutlet weak var dlClientTokenDisplay: UILabel!
    @IBOutlet weak var dlSettingsDisplay: UILabel!
    @IBOutlet weak var clearAppLinkButton: UIButton!

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

    var applePayCaptureBillingAddress = false
    var applePayBillingAdditionalContactFields: [PrimerApplePayOptions.RequiredContactField]? = []
    var applePayCaptureShippingDetails = false
    var applePayRequireShippingMethod = false
    var applePayShippingAdditionalContactFields: [PrimerApplePayOptions.RequiredContactField]? = []
    var applePayCheckProvidedNetworks = false

    private var deepLinkSettings: PrimerSettings?
    private var deepLinkClientToken: String?

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

        customerIdTextField.addTarget(
            self, action: #selector(customerIdChanged(_:)), for: .editingDidEnd)

        handleAppetizeIfNeeded(AppLinkConfigProvider())

        render()

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleAppetizeConfig), name: NSNotification.Name.appetizeURLHandled,
            object: nil)
    }

    @objc func handleAppetizeConfig(_ notification: NSNotification) {
        if let payloadProvider = notification.object as? DeeplinkConfigProvider {
            handleAppetizeIfNeeded(AppLinkConfigProvider(payloadProvider: payloadProvider))
        }
    }

    private func handleAppetizeIfNeeded(_ configProvider: AppLinkConfigProvider) {
        if let settings = configProvider.fetchConfig() {
            self.deepLinkSettings = settings
            self.dlSettingsDisplay.text = prettyPrint(settings)
        }
        if let clientToken = configProvider.fetchClientToken() {
            self.deepLinkClientToken = clientToken
            clientTokenTextField.text = clientToken
            self.dlClientTokenDisplay.text = clientToken
            self.testingModeSegmentedControl.selectedSegmentIndex = RenderMode.deepLink.rawValue
            setRenderMode(.deepLink)
        }
    }

    // Function to pretty print
    private func prettyPrint<T: Codable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8) ?? "Encoding failed"
        } catch {
            return "Failed to encode: \(error)"
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
            deepLinkStackView.isHidden = true

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
            deepLinkStackView.isHidden = true

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
            deepLinkStackView.isHidden = true

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
        case .deepLink:
            [environmentStackView,
            testParamsGroupStackView,
            apiKeyStackView,
            clientTokenStackView,
            sdkSettingsStackView,
            orderStackView,
            customerStackView,
            surchargeGroupStackView,
             klarnaEMDStackView].forEach { $0.isHidden = true }
            deepLinkStackView.isHidden = false
        }

        gesturesDismissalSwitch.isOn = true  // Default value
        closeButtonDismissalSwitch.isOn = false  // Default false

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
                target: self, action: #selector(lineItemTapped))
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
        setRenderMode(RenderMode(rawValue: sender.selectedSegmentIndex) ?? .createClientSession)
    }

    private func setRenderMode(_ renderMode: RenderMode) {
        self.renderMode = renderMode
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
            apiVersion = .V2_4
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
            let option = ClientSessionRequestBody.PaymentMethod.PaymentMethodOption(surcharge: nil,
                                                                                    instalmentDuration: nil,
                                                                                    extraMerchantData: nil,
                                                                                    captureVaultedCardCvv: enableCVVRecaptureFlowSwitch.isOn,
                                                                                    merchantName: nil,
                                                                                    networks: nil)

            clientSession.paymentMethod?.options?.PAYMENT_CARD = option
        }

        let applePayOptions = ClientSessionRequestBody.PaymentMethod.PaymentMethodOption(surcharge: nil,
                                                                                         instalmentDuration: nil, 
                                                                                         extraMerchantData: nil, 
                                                                                         captureVaultedCardCvv: nil, 
                                                                                         merchantName: "Primer Merchant iOS", 
                                                                                         networks: nil)

        clientSession.paymentMethod?.options?.APPLE_PAY = applePayOptions

        if let text = surchargeTextField.text, let amount = Int(text), surchargeSwitch.isOn {
            let surcharge = ClientSessionRequestBody.PaymentMethod.SurchargeOption(amount: amount)
            var networkOptionGroup = ClientSessionRequestBody.PaymentMethod.NetworkOptionGroup()
            networkOptionGroup.VISA = ClientSessionRequestBody.PaymentMethod.NetworkOption(surcharge: surcharge)
            networkOptionGroup.JCB = ClientSessionRequestBody.PaymentMethod.NetworkOption(surcharge: surcharge)
            networkOptionGroup.MASTERCARD = ClientSessionRequestBody.PaymentMethod.NetworkOption(surcharge: surcharge)
            let paymentCardOptions = ClientSessionRequestBody.PaymentMethod.PaymentMethodOption(surcharge: nil,
                                                                                                instalmentDuration: nil,
                                                                                                extraMerchantData: nil,
                                                                                                captureVaultedCardCvv: nil,
                                                                                                merchantName: "Primer Merchant iOS",
                                                                                                networks: networkOptionGroup)
            clientSession.paymentMethod?.options?.PAYMENT_CARD = paymentCardOptions
        }

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
                "userAgent": .string("iOS")
            ])
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
                title: "Error", message: "Please choose Test Scenario", preferredStyle: .alert)
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
                let alert = UIAlertController(
                    title: "Error", message: "Please choose failure flow in the Failure Parameters",
                    preferredStyle: .alert)
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
                let alert = UIAlertController(
                    title: "Error", message: "Please choose 3DS scenario", preferredStyle: .alert)
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

        let settings = populateSettingsFromUI(dropIn: true)

        switch renderMode {
        case .createClientSession, .testScenario:
            configureClientSession()
            if case .testScenario = renderMode {
                configureTestScenario()
            }
            let vc = MerchantDropInUIViewController.instantiate(
                settings: settings, clientSession: clientSession, clientToken: nil)
            navigationController?.pushViewController(vc, animated: true)

        case .clientToken:
            let vc = MerchantDropInUIViewController.instantiate(
                settings: settings, clientSession: nil, clientToken: clientTokenTextField.text)
            navigationController?.pushViewController(vc, animated: true)

        case .deepLink:
            if let clientToken = self.deepLinkClientToken, let settings = self.deepLinkSettings {
                let vc = MerchantDropInUIViewController.instantiate(
                    settings: settings, clientSession: nil, clientToken: clientToken)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    @IBAction func primerHeadlessButtonTapped(_ sender: Any) {
        customDefinedApiKey = (apiKeyTextField.text ?? "").isEmpty ? nil : apiKeyTextField.text

        let settings = populateSettingsFromUI(dropIn: false)

        switch renderMode {
        case .createClientSession, .testScenario:
            configureClientSession()
            if case .testScenario = renderMode {
                configureTestScenario()
            }
            let vc = MerchantHeadlessCheckoutAvailablePaymentMethodsViewController.instantiate(
                settings: settings,
                clientSession: clientSession,
                clientToken: nil)
            navigationController?.pushViewController(vc, animated: true)
        case .clientToken:
            let vc = MerchantHeadlessCheckoutAvailablePaymentMethodsViewController.instantiate(
                settings: settings,
                clientSession: nil,
                clientToken: clientTokenTextField.text)
            navigationController?.pushViewController(vc, animated: true)
        case .deepLink:
            if let clientToken = self.deepLinkClientToken, let settings = self.deepLinkSettings {
                let vc = MerchantHeadlessCheckoutAvailablePaymentMethodsViewController.instantiate(
                    settings: settings,
                    clientSession: nil,
                    clientToken: clientToken)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    private func populateSettingsFromUI(dropIn: Bool) -> PrimerSettings {
        var uiOptions: PrimerUIOptions?
        if dropIn {
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

            uiOptions = PrimerUIOptions(
                isInitScreenEnabled: !disableInitScreenSwitch.isOn,
                isSuccessScreenEnabled: !disableSuccessScreenSwitch.isOn,
                isErrorScreenEnabled: !disableErrorScreenSwitch.isOn,
                dismissalMechanism: selectedDismissalMechanisms,
                cardFormUIOptions: PrimerCardFormUIOptions(payButtonAddNewCard: addNewCardSwitch.isOn),
                theme: applyThemingSwitch.isOn ? CheckoutTheme.tropical : nil)
        }

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
                    merchantIdentifier: "merchant.dx.team",
                    merchantName: merchantNameTextField.text ?? "Primer Merchant",
                    isCaptureBillingAddressEnabled: applePayCaptureBillingAddress,
                    showApplePayForUnsupportedDevice: false,
                    checkProvidedNetworks: applePayCheckProvidedNetworks,
                    shippingOptions: shippingOptions,
                    billingOptions: billingOptions),
                stripeOptions: stripePublishableKey == nil ? nil : PrimerStripeOptions(publishableKey: stripePublishableKey!, mandateData: mandateData)),
            uiOptions: uiOptions,
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false),
            apiVersion: apiVersion
        )

        return settings
    }

    @objc func customerIdChanged(_ textField: UITextField!) {
        guard let text = customerIdTextField.text else { return }
        UserDefaults.standard.set(text, forKey: MerchantMockDataManager.customerIdStorageKey)
    }

    @IBAction func clearAppLinkButtonTapped(_ sender: Any) {
        self.deepLinkClientToken = nil
        self.deepLinkSettings = nil
        self.testingModeSegmentedControl.selectedSegmentIndex = RenderMode.createClientSession.rawValue
        setRenderMode(.createClientSession)
        dlSettingsDisplay.text = ""
        dlClientTokenDisplay.text = ""
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

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
    -> String? {
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

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
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
