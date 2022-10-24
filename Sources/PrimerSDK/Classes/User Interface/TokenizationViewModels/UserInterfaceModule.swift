//
//  UserInterfaceModule.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//


#if canImport(UIKit)

import UIKit

//protocol UserInterfaceModuleProtocol {
//
//    var paymentMethodModule: PaymentMethodModuleProtocol! { get }
//    var logo: UIImage? { get }
//    var invertedLogo: UIImage? { get }
//    var icon: UIImage? { get }
//    var surchargeSectionText: String? { get }
//    var paymentMethodButton: PrimerButton { get }
//    var submitButton: PrimerButton? { get }
//
//    init(paymentMethodModule: PaymentMethodModuleProtocol)
//    func makeLogoImageView(withSize size: CGSize?) -> UIImageView?
//    func makeIconImageView(withDimension dimension: CGFloat) -> UIImageView?
//}

class UserInterfaceModule: NSObject {
    
    // MARK: - PROPERTIES
    
    weak var paymentMethodModule: PaymentMethodModuleProtocol!
    internal let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    internal lazy var paymentMethodType: PrimerPaymentMethodType? = {
        return PrimerPaymentMethodType(rawValue: self.paymentMethodModule.paymentMethodConfiguration.type)
    }()
    
    internal lazy var inputs: [Input]? = {
        guard let paymentMethodType = self.paymentMethodType else { return nil }
        
        switch paymentMethodType {
        case .adyenBlik:
            return [self.paymentMethodModule.userInterfaceModule.adyenBlikInputView]
        case .adyenMBWay:
            return [self.paymentMethodModule.userInterfaceModule.mbwayInputView]
        default:
            return nil
        }
    }()
    
    var themeMode: PrimerTheme.Mode {
        if let baseLogoImage = paymentMethodModule.paymentMethodConfiguration.baseLogoImage {
            if UIScreen.isDarkModeEnabled {
                if baseLogoImage.dark != nil {
                    return .dark
                } else if baseLogoImage.colored != nil {
                    return .colored
                } else if baseLogoImage.light != nil {
                    return .light
                }
            } else {
                if baseLogoImage.colored != nil {
                    return .colored
                } else if baseLogoImage.light != nil {
                    return .light
                } else if baseLogoImage.dark != nil {
                    return .dark
                }
            }
        }
        
        if UIScreen.isDarkModeEnabled {
            return .dark
        } else {
            return .colored
        }
    }
    
    var surchargeSectionText: String? {
        switch self.paymentMethodModule.paymentMethodConfiguration.type {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            return Strings.CardFormView.additionalFeesTitle
        default:
            guard let currency = AppState.current.currency else { return nil }
            guard let availablePaymentMethods = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods, !availablePaymentMethods.isEmpty else { return nil }
            guard let str = availablePaymentMethods.filter({ $0.type == self.paymentMethodModule.paymentMethodConfiguration.type }).first?.surcharge?.toCurrencyString(currency: currency) else { return nil }
            return "+\(str)"
        }
    }
    
    var cardNetwork: CardNetwork? {
        didSet {
            cvvField.cardNetwork = cardNetwork ?? .unknown
        }
    }
    
    // MARK: - INITIALIZATION
    
    required init(paymentMethodModule: PaymentMethodModuleProtocol) {
        self.paymentMethodModule = paymentMethodModule
    }
    
    // MARK: - ACTIONS
    
    @IBAction internal func paymentMethodButtonTapped(_ sender: UIButton) {
        self.paymentMethodModule.startFlow()
    }
    
    @IBAction internal func submitButtonTapped(_ sender: UIButton) {
        self.paymentMethodModule.tokenizationModule.submitTokenizationData()
//        self.paymentMethodModule.tokenizationModule.submitButtonTapped()
    }
    
    @objc
    internal func copyToClipboardTapped(_ sender: UIButton) {
        UIPasteboard.general.string = PrimerAPIConfigurationModule.decodedJWTToken?.accountNumber
        
        log(logLevel: .debug, message: "📝📝📝📝 Copied: \(String(describing: UIPasteboard.general.string))")
        
        DispatchQueue.main.async {
            sender.isSelected = true
        }
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
            DispatchQueue.main.async {
                sender.isSelected = false
            }
            timer.invalidate()
        }
    }
    
    // MARK: - IMAGES
    
    internal var logo: UIImage? {
        return paymentMethodModule.paymentMethodConfiguration.logo
    }
    
    internal var invertedLogo: UIImage? {
        return paymentMethodModule.paymentMethodConfiguration.invertedLogo
    }
    
    var icon: UIImage? {
        var fileName = paymentMethodModule.paymentMethodConfiguration.type.lowercased().replacingOccurrences(of: "_", with: "-")
        fileName += "-icon"
        
        switch self.themeMode {
        case .colored:
            fileName += "-colored"
        case .dark:
            fileName += "-dark"
        case .light:
            fileName += "-colored"
        }
        
        return UIImage(named: fileName, in: Bundle.primerResources, compatibleWith: nil)
    }
    
    // MARK: - BUTTONS & VIEWS
    
    lazy var paymentMethodButton: PrimerButton = {
        let paymentMethodButtonBuilder = UserInterfaceModule.PaymentMethodButtonBuilder(paymentMethodConfiguration: self.paymentMethodModule.paymentMethodConfiguration)
        paymentMethodButtonBuilder.button.addTarget(self, action: #selector(paymentMethodButtonTapped(_:)), for: .touchUpInside)
        return paymentMethodButtonBuilder.button
    }()
    
    lazy var submitButton: PrimerButton? = {
        guard let paymentMethodType = self.paymentMethodType else { return nil }
        
        var title: String = ""
        
        switch paymentMethodType {
        case .paymentCard,
                .adyenMBWay:
            switch PrimerInternal.shared.intent {
            case .checkout:
                let universalCheckoutViewModel: UniversalCheckoutViewModelProtocol = UniversalCheckoutViewModel()
                title = Strings.PaymentButton.pay
                if let amountStr = universalCheckoutViewModel.amountStr {
                    title += " \(amountStr))"
                }
                
            case .vault:
                title = Strings.PrimerCardFormView.addCardButtonTitle
                
            case .none:
                precondition(false, "Intent should have been set")
            }
            
            return makePrimerButtonWithTitleText(title, isEnabled: false)
            
        case .primerTestKlarna,
                .primerTestPayPal,
                .primerTestSofort:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.pay, isEnabled: false)
            
        case .adyenBlik,
                .xfersPayNow:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.confirm, isEnabled: false)
            
        case .adyenMultibanco:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.confirmToPay, isEnabled: true)
            
        case .adyenBancontactCard:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.pay, isEnabled: false)
            
        default:
            return nil
        }
    }()
    
    lazy var inputView: PrimerView? = {
        let paymentMethodConfiguration = self.paymentMethodModule.paymentMethodConfiguration
        
        if paymentMethodConfiguration.implementationType == .webRedirect {
            return nil
        }
        
        guard let paymentMethodType = self.paymentMethodType else { return nil }
        
        switch paymentMethodType {
        case .adyenBancontactCard,
                .paymentCard:
            return self.cardFormView
            
        case .adyenBlik,
                .adyenMBWay:
            guard let inputs = inputs else { return nil }
            let inputTextFieldsStackViews = createInputTextFieldsStackViews(inputs: inputs, textFieldsDelegate: self)
            
            var arr: [[UIView]] = []
            for stackView in inputTextFieldsStackViews {
                
                var inArr: [UIView] = []
                for arrangedSubview in stackView.arrangedSubviews {
                    inArr.append(arrangedSubview)
                }
                
                if !inArr.isEmpty {
                    arr.append(inArr)
                }
            }
            
            return PrimerFormView(frame: .zero, formViews: arr, horizontalStackDistribution: .fillProportionally)
            
        case .adyenMultibanco:
            return voucherConfirmationInfoView
            
        default:
            return nil
        }
    }()
    
    lazy var resultView: PrimerView? = {
        guard let paymentMethodType = self.paymentMethodType else { return nil }
        
        switch paymentMethodType {
        case .adyenMBWay:
            return self.makePaymentPendingInfoView(logo: nil, message: Strings.MBWay.completeYourPayment)
            
        case .adyenMultibanco:
            return self.voucherInfoView
            
        default:
            return nil
        }
    }()
    
    // MARK: - INPUT VIEWS
    
    // MARK: - Card Form Input View
    
    lazy var cardFormView: PrimerFormView? = {
        guard let paymentMethodType = self.paymentMethodType else { return nil }
        
        switch paymentMethodType {
        case .adyenBancontactCard,
                .paymentCard:
            var formViews: [[UIView?]] = [
                [cardNumberContainerView],
                [expiryDateContainerView],
                [cardholderNameContainerView],
            ]
            if isRequiringCVVInput {
                // PAYMENT_CARD
                formViews[1].append(cvvContainerView)
            }
            
            formViews.append(contentsOf: allVisibleBillingAddressFieldContainerViews)
            
            return PrimerFormView(frame: .zero, formViews: formViews)
            
        default:
            return nil
        }
    }()
    
    // MARK: Card number
    
    internal lazy var cardNumberField: PrimerCardNumberFieldView = {
        PrimerCardNumberField.cardNumberFieldViewWithDelegate(self)
    }()
    
    internal lazy var cardNumberContainerView: PrimerCustomFieldView = {
        PrimerCardNumberField.cardNumberContainerViewWithFieldView(cardNumberField)
    }()

    // MARK: Cardholder name

    internal lazy var cardholderNameField: PrimerCardholderNameFieldView? = {
        if !PrimerCardholderNameField.isCardholderNameFieldEnabled { return nil }
        return PrimerCardholderNameField.cardholderNameFieldViewWithDelegate(self)
    }()
    
    internal lazy var cardholderNameContainerView: PrimerCustomFieldView? = {
        if !PrimerCardholderNameField.isCardholderNameFieldEnabled { return nil }
        return PrimerCardholderNameField.cardholderNameContainerViewFieldView(cardholderNameField)
    }()
        
    // MARK: Expiry date
    
    internal lazy var expiryDateField: PrimerExpiryDateFieldView = {
        return PrimerEpiryDateField.expiryDateFieldViewWithDelegate(self)
    }()
    
    internal lazy var expiryDateContainerView: PrimerCustomFieldView = {
        return PrimerEpiryDateField.expiryDateContainerViewWithFieldView(expiryDateField)
    }()

    // MARK: CVV
    
    internal lazy var cvvField: PrimerCVVFieldView = {
        PrimerCVVField.cvvFieldViewWithDelegate(self)
    }()
        
    internal lazy var cvvContainerView: PrimerCustomFieldView = {
        PrimerCVVField.cvvContainerViewFieldView(cvvField)
    }()
    
    internal var billingAddressFields: [[BillingAddressField]] {
        guard isShowingBillingAddressFieldsRequired else { return [] }
        return [
            [countryField],
            [firstNameField, lastNameField],
            [addressLine1Field],
            [addressLine2Field],
            [postalCodeField, cityField],
            [stateField],
        ]
    }
    
    internal var allVisibleBillingAddressFieldContainerViews: [[PrimerCustomFieldView]] {
        let allVisibleBillingAddressFields = billingAddressFields.map { $0.filter { $0.isFieldHidden == false } }
        return allVisibleBillingAddressFields.map { $0.map { $0.containerFieldView } }
    }
    
    // MARK: Billing address
        
    internal var countryField: BillingAddressField {
        (countryFieldView, countryFieldContainerView, billingAddressCheckoutModuleOptions?.countryCode == false)
    }
        
    // MARK: First name
    
    internal lazy var firstNameFieldView: PrimerFirstNameFieldView = {
        PrimerFirstNameField.firstNameFieldViewWithDelegate(self)
    }()
        
    internal lazy var firstNameContainerView: PrimerCustomFieldView = {
        PrimerFirstNameField.firstNameFieldContainerViewFieldView(firstNameFieldView)
    }()
    
    internal var firstNameField: BillingAddressField {
        (firstNameFieldView, firstNameContainerView, billingAddressCheckoutModuleOptions?.firstName == false)
    }
    
    // MARK: Last name
    
    internal lazy var lastNameFieldView: PrimerLastNameFieldView = {
        PrimerLastNameField.lastNameFieldViewWithDelegate(self)
    }()
            
    internal lazy var lastNameContainerView: PrimerCustomFieldView = {
        PrimerLastNameField.lastNameFieldContainerViewFieldView(lastNameFieldView)
    }()
    
    internal var lastNameField: BillingAddressField {
        (lastNameFieldView, lastNameContainerView, billingAddressCheckoutModuleOptions?.lastName == false)
    }
    
    // MARK: Address Line 1

    internal lazy var addressLine1FieldView: PrimerAddressLine1FieldView = {
        PrimerAddressLine1Field.addressLine1FieldViewWithDelegate(self)
    }()
            
    internal lazy var addressLine1ContainerView: PrimerCustomFieldView = {
        PrimerAddressLine1Field.addressLine1ContainerViewFieldView(addressLine1FieldView)
    }()
    
    internal var addressLine1Field: BillingAddressField {
        (addressLine1FieldView, addressLine1ContainerView, billingAddressCheckoutModuleOptions?.addressLine1 == false)
    }

    // MARK: Address Line 2

    internal lazy var addressLine2FieldView: PrimerAddressLine2FieldView = {
        PrimerAddressLine2Field.addressLine2FieldViewWithDelegate(self)
    }()
            
    internal lazy var addressLine2ContainerView: PrimerCustomFieldView = {
        PrimerAddressLine2Field.addressLine2ContainerViewFieldView(addressLine2FieldView)
    }()
    
    internal var addressLine2Field: BillingAddressField {
        (addressLine2FieldView, addressLine2ContainerView, billingAddressCheckoutModuleOptions?.addressLine2 == false)
    }
    
    // MARK: Postal code
    
    internal lazy var postalCodeFieldView: PrimerPostalCodeFieldView = {
        PrimerPostalCodeField.postalCodeViewWithDelegate(self)
    }()
        
    internal lazy var postalCodeContainerView: PrimerCustomFieldView = {
        PrimerPostalCodeField.postalCodeContainerViewFieldView(postalCodeFieldView)
    }()
    
    internal var postalCodeField: BillingAddressField {
        (postalCodeFieldView, postalCodeContainerView, billingAddressCheckoutModuleOptions?.postalCode == false)
    }
    
    // MARK: City

    internal lazy var cityFieldView: PrimerCityFieldView = {
        PrimerCityField.cityFieldViewWithDelegate(self)
    }()
            
    internal lazy var cityContainerView: PrimerCustomFieldView = {
        PrimerCityField.cityFieldContainerViewFieldView(cityFieldView)
    }()
    
    internal var cityField: BillingAddressField {
        (cityFieldView, cityContainerView, billingAddressCheckoutModuleOptions?.city == false)
    }
    
    // MARK: State

    internal lazy var stateFieldView: PrimerStateFieldView = {
        PrimerStateField.stateFieldViewWithDelegate(self)
    }()
            
    internal lazy var stateContainerView: PrimerCustomFieldView = {
        PrimerStateField.stateFieldContainerViewFieldView(stateFieldView)
    }()
    
    internal var stateField: BillingAddressField {
        (stateFieldView, stateContainerView, billingAddressCheckoutModuleOptions?.state == false)
    }
    
    // MARK: Country
        
    internal lazy var countryFieldView: PrimerCountryFieldView = {
        PrimerCountryField.countryFieldViewWithDelegate(self)
    }()

    internal lazy var countryFieldContainerView: PrimerCustomFieldView = {
        PrimerCountryField.countryContainerViewFieldView(countryFieldView, openCountriesListPressed: {
            DispatchQueue.main.async {
                let countrySelectorViewController = self.createCountrySelectorViewController()
                PrimerUIManager.primerRootViewController?.show(viewController: countrySelectorViewController)
            }
        })
    }()
    
    // MARK: - Adyen Blik Input
    
    internal var adyenBlikInputView: Input = {
        let input1 = Input()
        input1.name = "OTP"
        input1.topPlaceholder = Strings.Blik.inputTopPlaceholder
        input1.textFieldPlaceholder = Strings.Blik.inputTextFieldPlaceholder
        input1.keyboardType = .numberPad
        input1.descriptor = Strings.Blik.inputDescriptor
        input1.allowedCharacterSet = CharacterSet.decimalDigits
        input1.maxCharactersAllowed = 6
        input1.isValid = { text in
            return text.isNumeric && text.count >= 6
        }
        
        return input1
    }()
        
    // MARK: - Adyen MBWay Input View
    
    internal var mbwayTopLabelView: UILabel = {
        let label = UILabel()
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        label.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        label.text = Strings.MBWay.inputTopPlaceholder
        label.textColor = theme.text.system.color
        return label
    }()
    
    internal var prefixSelectorButton: PrimerButton = {
        let countryCodeFlag = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode?.flag ?? ""
        let countryDialCode = CountryCode.phoneNumberCountryCodes.first(where: { $0.code == PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode?.rawValue})?.dialCode ?? ""
        
        let prefixSelectorButton = PrimerButton()
        prefixSelectorButton.isAccessibilityElement = true
        prefixSelectorButton.accessibilityIdentifier = "prefix_selector_btn"
        prefixSelectorButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        prefixSelectorButton.setTitle("\(countryCodeFlag) \(countryDialCode)", for: .normal)
        prefixSelectorButton.setTitleColor(.black, for: .normal)
        prefixSelectorButton.clipsToBounds = true
        prefixSelectorButton.isUserInteractionEnabled = false
        prefixSelectorButton.translatesAutoresizingMaskIntoConstraints = false
        prefixSelectorButton.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
        prefixSelectorButton.contentVerticalAlignment = .top
        return prefixSelectorButton
    }()
    
    internal var mbwayInputView: Input = {
        let input1 = Input()
        input1.keyboardType = .numberPad
        input1.allowedCharacterSet = CharacterSet(charactersIn: "0123456789")
        input1.isValid = { text in
            return text.isNumeric && text.count >= 8
        }
        return input1
    }()
    
    // MARK: - Adyen Multibanco Input View
    
    internal var voucherInfoView: PrimerFormView? {
        guard let paymentMethodType = self.paymentMethodType, paymentMethodType == .adyenMultibanco else { return nil }
        
        // Complete your payment

        let completeYourPaymentLabel = UILabel()
        completeYourPaymentLabel.text = Strings.VoucherInfoPaymentView.completeYourPayment
        completeYourPaymentLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.title)
        completeYourPaymentLabel.textColor = theme.text.title.color

        let descriptionLabel = UILabel()
        descriptionLabel.textColor = .gray600
        descriptionLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.body)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = Strings.VoucherInfoPaymentView.descriptionLabel

        // Expires at

        let expiresAtContainerStackView = UIStackView()
        expiresAtContainerStackView.axis = .horizontal
        expiresAtContainerStackView.spacing = 8.0

        let calendarImage = UIImage(named: "calendar", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        let calendarImageView = UIImageView(image: calendarImage)
        calendarImageView.tintColor = .gray600
        calendarImageView.clipsToBounds = true
        calendarImageView.contentMode = .scaleAspectFit
        expiresAtContainerStackView.addArrangedSubview(calendarImageView)

        if let expDate = PrimerAPIConfigurationModule.decodedJWTToken?.expiresAt {
            let expiresAtPrefixLabel = UILabel()
            let expiresAtAttributedString = NSMutableAttributedString()
            let prefix = NSAttributedString(
                string: Strings.VoucherInfoPaymentView.expiresAt,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray600])
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            let expiresAtDate = NSAttributedString(
                string: formatter.string(from: expDate),
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            expiresAtAttributedString.append(prefix)
            expiresAtAttributedString.append(NSAttributedString(string: " ", attributes: nil))
            expiresAtAttributedString.append(expiresAtDate)
            expiresAtPrefixLabel.attributedText = expiresAtAttributedString
            expiresAtPrefixLabel.numberOfLines = 0
            expiresAtPrefixLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.body)
            expiresAtContainerStackView.addArrangedSubview(expiresAtPrefixLabel)
        }

        // Voucher info container Stack View

        let voucherInfoContainerStackView = PrimerStackView()
        voucherInfoContainerStackView.axis = .vertical
        voucherInfoContainerStackView.spacing = 12.0
        voucherInfoContainerStackView.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        voucherInfoContainerStackView.layer.cornerRadius = PrimerDimensions.cornerRadius / 2
        voucherInfoContainerStackView.layer.borderColor = UIColor.gray200.cgColor
        voucherInfoContainerStackView.layer.borderWidth = 2.0
        voucherInfoContainerStackView.isLayoutMarginsRelativeArrangement = true
        voucherInfoContainerStackView.layer.cornerRadius = 8.0

        for voucherValue in VoucherValue.currentVoucherValues {

            if voucherValue.value != nil {

                let voucherValueStackView = PrimerStackView()
                voucherValueStackView.axis = .horizontal
                voucherValueStackView.spacing = 12.0
                voucherValueStackView.distribution = .fillProportionally

                let voucherValueLabel = UILabel()
                voucherValueLabel.text = voucherValue.description
                voucherValueLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
                voucherValueLabel.textColor = .gray600
                voucherValueStackView.addArrangedSubview(voucherValueLabel)

                let voucherValueText = UILabel()
                voucherValueText.text = voucherValue.value
                voucherValueText.font = UIFont.boldSystemFont(ofSize: PrimerDimensions.Font.label)
                voucherValueText.textColor = theme.text.title.color
                voucherValueText.setContentHuggingPriority(.required, for: .horizontal)
                voucherValueText.setContentCompressionResistancePriority(.required, for: .horizontal)
                voucherValueStackView.addArrangedSubview(voucherValueText)

                voucherInfoContainerStackView.addArrangedSubview(voucherValueStackView)

                if let lastValue = VoucherValue.currentVoucherValues.last, voucherValue != lastValue  {
                    // Separator view
                    let separatorView = PrimerView()
                    separatorView.backgroundColor = .gray200
                    separatorView.translatesAutoresizingMaskIntoConstraints = false
                    separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
                    voucherInfoContainerStackView.addArrangedSubview(separatorView)
                }
            }
        }

//                let copyToClipboardImage = UIImage(named: "copy-to-clipboard", in: Bundle.primerResources, compatibleWith: nil)
//                let copiedToClipboardImage = UIImage(named: "check-circle", in: Bundle.primerResources, compatibleWith: nil)
//                let copyToClipboardButton = UIButton(type: .custom)
//                copyToClipboardButton.setImage(copyToClipboardImage, for: .normal)
//                copyToClipboardButton.setImage(copiedToClipboardImage, for: .selected)
//                copyToClipboardButton.translatesAutoresizingMaskIntoConstraints = false
//                copyToClipboardButton.addTarget(self, action: #selector(copyToClipboardTapped), for: .touchUpInside)
//                entityStackView.addArrangedSubview(copyToClipboardButton)

//        self.uiModule.submitButton = nil

        let views = [[completeYourPaymentLabel],
                     [expiresAtContainerStackView],
                     [voucherInfoContainerStackView]]

        return PrimerFormView(formViews: views)
    }
    
    internal lazy var voucherConfirmationInfoView: PrimerFormView = {
        // Complete your payment
        let confirmationTitleLabel = UILabel()
        confirmationTitleLabel.text = Strings.VoucherInfoConfirmationSteps.confirmationStepTitle
        confirmationTitleLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.title)
        confirmationTitleLabel.textColor = theme.text.title.color
        
        // Confirmation steps
        let confirmationStepContainerStackView = PrimerStackView()
        confirmationStepContainerStackView.axis = .vertical
        confirmationStepContainerStackView.spacing = 16.0
        confirmationStepContainerStackView.isLayoutMarginsRelativeArrangement = true
        
        let stepsTexts = [Strings.VoucherInfoConfirmationSteps.confirmationStep1LabelText,
                          Strings.VoucherInfoConfirmationSteps.confirmationStep2LabelText,
                          Strings.VoucherInfoConfirmationSteps.confirmationStep3LabelText]
        
        for stepsText in stepsTexts {
            
            let confirmationStepLabel = UILabel()
            confirmationStepLabel.textColor = .gray600
            confirmationStepLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
            confirmationStepLabel.numberOfLines = 0
            confirmationStepLabel.text = stepsText
            
            confirmationStepContainerStackView.addArrangedSubview(confirmationStepLabel)
        }
        
        let views = [[confirmationTitleLabel],
                     [confirmationStepContainerStackView]]
        
        return PrimerFormView(formViews: views)
    }()
    
    // MARK: - Rapyd Fast Input View
    
    internal var rapydFastAccountInfoView: PrimerFormView {
        
        // Complete your payment
        
        let completeYourPaymentLabel = UILabel()
        completeYourPaymentLabel.text = Strings.AccountInfoPaymentView.completeYourPayment
        completeYourPaymentLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.title)
        completeYourPaymentLabel.textColor = theme.text.title.color
        
        // Due at
        
        let dueAtContainerStackView = UIStackView()
        dueAtContainerStackView.axis = .horizontal
        dueAtContainerStackView.spacing = 8.0
        
        let calendarImage = UIImage(named: "calendar", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        let calendarImageView = UIImageView(image: calendarImage)
        calendarImageView.tintColor = .gray600
        calendarImageView.clipsToBounds = true
        calendarImageView.contentMode = .scaleAspectFit
        dueAtContainerStackView.addArrangedSubview(calendarImageView)
        
        if let expDate = PrimerAPIConfigurationModule.decodedJWTToken?.expDate {
            let dueAtPrefixLabel = UILabel()
            let dueDateAttributedString = NSMutableAttributedString()
            let prefix = NSAttributedString(
                string: Strings.AccountInfoPaymentView.dueAt,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray600])
            let formatter = DateFormatter().withExpirationDisplayDateFormat()
            let dueAtDate = NSAttributedString(
                string: formatter.string(from: expDate),
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            dueDateAttributedString.append(prefix)
            dueDateAttributedString.append(NSAttributedString(string: " ", attributes: nil))
            dueDateAttributedString.append(dueAtDate)
            dueAtPrefixLabel.attributedText = dueDateAttributedString
            dueAtPrefixLabel.numberOfLines = 0
            dueAtPrefixLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.body)
            dueAtContainerStackView.addArrangedSubview(dueAtPrefixLabel)
        }
        
        // Account number
        
        let accountNumberInfoContainerStackView = PrimerStackView()
        accountNumberInfoContainerStackView.axis = .vertical
        accountNumberInfoContainerStackView.spacing = 12.0
        accountNumberInfoContainerStackView.addBackground(color: .gray100)
        accountNumberInfoContainerStackView.layoutMargins = UIEdgeInsets(top: PrimerDimensions.StackViewSpacing.default,
                                                                         left: PrimerDimensions.StackViewSpacing.default,
                                                                         bottom: PrimerDimensions.StackViewSpacing.default,
                                                                         right: PrimerDimensions.StackViewSpacing.default)
        accountNumberInfoContainerStackView.isLayoutMarginsRelativeArrangement = true
        accountNumberInfoContainerStackView.layer.cornerRadius = PrimerDimensions.cornerRadius
        
        let transferFundsLabel = UILabel()
        transferFundsLabel.text = Strings.AccountInfoPaymentView.pleaseTransferFunds
        transferFundsLabel.numberOfLines = 0
        transferFundsLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
        transferFundsLabel.textColor = theme.text.title.color
        accountNumberInfoContainerStackView.addArrangedSubview(transferFundsLabel)
        
        let accountNumberStackView = PrimerStackView()
        accountNumberStackView.axis = .horizontal
        accountNumberStackView.spacing = 12.0
        accountNumberStackView.heightAnchor.constraint(equalToConstant: 56.0).isActive = true
        accountNumberStackView.addBackground(color: .white)
        accountNumberStackView.layoutMargins = UIEdgeInsets(top: PrimerDimensions.StackViewSpacing.default,
                                                            left: PrimerDimensions.StackViewSpacing.default,
                                                            bottom: PrimerDimensions.StackViewSpacing.default,
                                                            right: PrimerDimensions.StackViewSpacing.default)
        accountNumberStackView.layer.cornerRadius = PrimerDimensions.cornerRadius / 2
        accountNumberStackView.layer.borderColor = UIColor.gray200.cgColor
        accountNumberStackView.layer.borderWidth = 2.0
        accountNumberStackView.isLayoutMarginsRelativeArrangement = true
        accountNumberStackView.layer.cornerRadius = 8.0
        
        if let accountNumber = PrimerAPIConfigurationModule.decodedJWTToken?.accountNumber {
            let accountNumberLabel = UILabel()
            accountNumberLabel.text = accountNumber
            accountNumberLabel.font = UIFont.boldSystemFont(ofSize: PrimerDimensions.Font.label)
            accountNumberLabel.textColor = theme.text.title.color
            accountNumberStackView.addArrangedSubview(accountNumberLabel)
        }
        
        let copyToClipboardImage = UIImage(named: "copy-to-clipboard", in: Bundle.primerResources, compatibleWith: nil)
        let copiedToClipboardImage = UIImage(named: "check-circle", in: Bundle.primerResources, compatibleWith: nil)
        let copyToClipboardButton = UIButton(type: .custom)
        copyToClipboardButton.setImage(copyToClipboardImage, for: .normal)
        copyToClipboardButton.setImage(copiedToClipboardImage, for: .selected)
        copyToClipboardButton.translatesAutoresizingMaskIntoConstraints = false
        copyToClipboardButton.addTarget(self, action: #selector(copyToClipboardTapped), for: .touchUpInside)
        accountNumberStackView.addArrangedSubview(copyToClipboardButton)
        
        accountNumberInfoContainerStackView.addArrangedSubview(accountNumberStackView)
        
        let views = [[completeYourPaymentLabel],
                     [dueAtContainerStackView],
                     [accountNumberInfoContainerStackView]]
        
        return PrimerFormView(formViews: views)
    }
    
    // MARK: - VIEW CONTROLLERS
    
    internal func createCountrySelectorViewController() -> CountrySelectorViewController {
        let csvc = CountrySelectorViewController(paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type)
        csvc.didSelectCountryCode = { countryCode in
            self.countryFieldView.textField.text = "\(countryCode.flag) \(countryCode.country)"
            self.countryFieldView.countryCode = countryCode
            self.countryFieldView.validation = .valid
            self.countryFieldView.textFieldDidEndEditing(self.countryFieldView.textField)
            PrimerUIManager.primerRootViewController?.popViewController()
        }
        return csvc
    }
    
    internal func createBanksSelectorViewController(with banks: [AdyenBank]) -> BankSelectorViewController {
        let bsvc = BankSelectorViewController(
            paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
            navigationBarImage: self.paymentMethodModule.userInterfaceModule.invertedLogo,
            banks: banks)
        return bsvc
    }
    
    
    
//    func createCountriesTableView(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) -> UITableView {
//        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
//
//        let tableView = UITableView()
//        tableView.showsVerticalScrollIndicator = false
//        tableView.showsHorizontalScrollIndicator = false
//        tableView.backgroundColor = theme.view.backgroundColor
//
//        if #available(iOS 11.0, *) {
//            tableView.contentInsetAdjustmentBehavior = .never
//        }
//
//        tableView.rowHeight = 41
//        tableView.register(CountryTableViewCell.self, forCellReuseIdentifier: CountryTableViewCell.className)
//
//        tableView.dataSource = dataSource
//        tableView.delegate = delegate
//        return tableView
//    }
//
//    func createSearchableTextField(delegate: UITextFieldDelegate) -> PrimerSearchTextField {
//        let textField = PrimerSearchTextField(frame: .zero)
//        textField.translatesAutoresizingMaskIntoConstraints = false
//        textField.heightAnchor.constraint(equalToConstant: 35).isActive = true
//        textField.delegate = delegate
//        textField.borderStyle = .none
//        textField.layer.cornerRadius = 3.0
//        textField.font = UIFont.systemFont(ofSize: 16.0)
//        textField.placeholder = Strings.CountrySelector.searchCountryTitle
//        textField.rightViewMode = .always
//        return textField
//    }
}

#endif
