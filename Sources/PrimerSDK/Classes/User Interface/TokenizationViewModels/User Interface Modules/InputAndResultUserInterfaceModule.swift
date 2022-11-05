//
//  InputAndResultUserInterfaceModule.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 01/11/22.
//

#if canImport(UIKit)

class InputAndResultUserInterfaceModule: NewUserInterfaceModule {
    
    // MARK: -
    
    override var inputView: PrimerView? {
        get { _inputView }
        set { _inputView = newValue }
    }
    
    override var resultView: PrimerView? {
        get { _resultView }
        set { _resultView = newValue }
    }
    
    private lazy var _inputView: PrimerView? = {
                
        guard self.paymentMethodConfiguration.implementationType != .webRedirect,
              let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type) else { return nil }
        
        switch paymentMethodType {
            
        case .adyenBancontactCard:
            
            var formViews: [[UIView?]] = [
                [cardNumberContainerView],
                [expiryDateContainerView],
                [cardholderNameContainerView]
            ]
                        
            return PrimerFormView(frame: .zero, formViews: formViews)

        case .adyenBlik,
                .adyenMBWay:

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
    
    private lazy var _resultView: PrimerView? = {
       nil
    }()
    
//    private lazy var _resultView: PrimerView? = {
//
//        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type) else { return nil }
//
//        switch paymentMethodType {
//        case .adyenMBWay:
//            return self.makePaymentPendingInfoView(logo: self.navigationBarLogo, message: Strings.MBWay.completeYourPayment)
//        case .adyenBlik:
//            return self.makePaymentPendingInfoView(logo: self.navigationBarLogo, message: Strings.Blik.completeYourPayment)
//        case .adyenMultibanco:
//            return self.voucherInfoView
//
//        default:
//            return nil
//        }
//    }()
    
    // MARK: Primer Test
    
    private let decisions = PrimerTestPaymentMethodSessionInfo.FlowDecision.allCases
    var lastSelectedIndexPath: IndexPath?
    var decisionSelectionCompletion: ((PrimerTestPaymentMethodSessionInfo.FlowDecision) -> Void)?
    
    internal lazy var tableView: UITableView = {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.rowHeight = 56
        tableView.backgroundColor = theme.view.backgroundColor
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        tableView.register(FlowDecisionTableViewCell.self, forCellReuseIdentifier: FlowDecisionTableViewCell.identifier)
        tableView.register(HeaderFooterLabelView.self, forHeaderFooterViewReuseIdentifier: "header")
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    var viewHeight: CGFloat {
        180+(CGFloat(decisions.count)*tableView.rowHeight)
    }

    
    // MARK: Card Network
    
    var cardNetwork: CardNetwork?
    
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
    
    lazy var inputs: [Input] = {

        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type) else {
            return []
        }

        switch paymentMethodType {
        case .adyenBlik:
            return [adyenBlikInputView]
        case .adyenMBWay:
            return [mbwayInputView]
        default:
            return []
        }
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
    
    override var navigationBarLogo: UIImage? {
        
        guard let internaPaymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodConfiguration.type) else {
            return super.navigationBarLogo
        }
        
        switch internaPaymentMethodType {
        case .adyenBlik:
            return UIScreen.isDarkModeEnabled ? logo : UIImage(named: "blik-logo-light", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenMultibanco:
            return UIScreen.isDarkModeEnabled ? logo : UIImage(named: "multibanco-logo-light", in: Bundle.primerResources, compatibleWith: nil)
        default:
            return super.navigationBarLogo
        }
    }
    
    override func presentPreTokenizationViewControllerIfNeeded() -> Promise<Void> {
        return Promise { seal in
            switch self.paymentMethodConfiguration.type {
            case PrimerPaymentMethodType.adyenBlik.rawValue,
                PrimerPaymentMethodType.adyenMBWay.rawValue,
                PrimerPaymentMethodType.adyenMultibanco.rawValue:
                
                let pcfvc = PrimerInputViewController(
                    paymentMethodType: self.paymentMethodConfiguration.type,
                    userInterfaceModule: self)
                PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
                seal.fulfill()
                
            default:
                seal.fulfill()
            }
        }
    }
    
    override func presentPostPaymentViewControllerIfNeeded() -> Promise<Void> {
        return Promise { seal in
            switch self.paymentMethodConfiguration.type {
            case PrimerPaymentMethodType.adyenMBWay.rawValue:
                let vc = PrimerPaymentPendingInfoViewController(userInterfaceModule: self)
                PrimerUIManager.primerRootViewController?.show(viewController: vc)
                seal.fulfill()
            default:
                seal.fulfill()
            }
        }
    }
    
    override func presentResultViewControllerIfNeeded() -> Promise<Void> {
        return Promise { seal in
            switch self.paymentMethodConfiguration.type {
            case PrimerPaymentMethodType.adyenMultibanco.rawValue:
                
                let pcfvc = PrimerVoucherInfoPaymentViewController(
                    userInterfaceModule: self,
                    shouldShareVoucherInfoWithText: VoucherValue.sharableVoucherValuesText)
                
                PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
                seal.fulfill()
            default:
                seal.fulfill()
            }
        }
    }
    
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
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type), paymentMethodType == .adyenMultibanco else { return nil }
        
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

}

extension InputAndResultUserInterfaceModule: PrimerTextFieldViewDelegate {
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        showTexfieldViewErrorIfNeeded(for: primerTextFieldView, isValid: true)
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        
        guard let paymentMethodType =  PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type) else { return }

        switch paymentMethodType {
        case .adyenBancontactCard:
            autofocusToNextFieldIfNeeded(for: primerTextFieldView, isValid: isValid)
            showTexfieldViewErrorIfNeeded(for: primerTextFieldView, isValid: isValid)
//            enableSubmitButtonIfNeeded()
            
        default:
            return
        }
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork?) {
        
        guard let paymentMethodType =  PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type) else { return }
        
        switch paymentMethodType {
            
        case .adyenBancontactCard:

            self.cardNetwork = cardNetwork
            
            var network = self.cardNetwork?.rawValue.uppercased()
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
            
            if let cardNetwork = cardNetwork, cardNetwork != .unknown, cardNumberContainerView.rightImage2 == nil && cardNetwork.icon != nil {
                if network == nil || network == "UNKNOWN" {
                    network = "OTHER"
                }
                
                cardNumberContainerView.rightImage2 = cardNetwork.icon
                
                firstly {
                    clientSessionActionsModule.selectPaymentMethodIfNeeded(self.paymentMethodConfiguration.type, cardNetwork: network)
                }
                .done {
//                    self.updateButtonUI()
                }
                .catch { _ in }
            } else if cardNumberContainerView.rightImage2 != nil && cardNetwork?.icon == nil {
                cardNumberContainerView.rightImage2 = nil
                            
                firstly {
                    clientSessionActionsModule.unselectPaymentMethodIfNeeded()
                }
                .done {
//                    self.updateButtonUI()
                }
                .catch { _ in }
            }
            
        default:
            return
        }
    }
}

extension InputAndResultUserInterfaceModule {
    
    internal func showTexfieldViewErrorIfNeeded(for primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        if isValid == false {
            // We know for sure that the text is not valid, even if the user hasn't finished typing.
            if primerTextFieldView is PrimerCardNumberFieldView, !primerTextFieldView.isEmpty {
                cardNumberContainerView.errorText = Strings.CardFormView.CardNumber.invalidErrorMessage
            } else if primerTextFieldView is PrimerExpiryDateFieldView, !primerTextFieldView.isEmpty {
                expiryDateContainerView.errorText = Strings.CardFormView.ExpiryDate.invalidErrorMessage
            } else if primerTextFieldView is PrimerCardholderNameFieldView, !primerTextFieldView.isEmpty {
                cardholderNameContainerView?.errorText = Strings.CardFormView.Cardholder.invalidErrorMessage
            }
        } else {
            // We don't know for sure if the text is valid
            if primerTextFieldView is PrimerCardNumberFieldView {
                cardNumberContainerView.errorText = nil
            } else if primerTextFieldView is PrimerExpiryDateFieldView {
                expiryDateContainerView.errorText = nil
            } else if primerTextFieldView is PrimerCardholderNameFieldView {
                cardholderNameContainerView?.errorText = nil
            }
        }
    }
}


extension InputAndResultUserInterfaceModule {
    
    internal func createInputTextFieldsStackViews(inputs: [Input], textFieldsDelegate: PrimerTextFieldViewDelegate) -> [UIStackView] {
        var stackViews: [UIStackView] = []
        
        for input in inputs {
            let stackView = UIStackView()
            stackView.spacing = 2
            stackView.axis = .horizontal
            stackView.alignment = .fill
            stackView.distribution = .fillProportionally
            
            let inputStackView = UIStackView()
            inputStackView.spacing = 2
            inputStackView.axis = .vertical
            inputStackView.alignment = .fill
            inputStackView.distribution = .fill
            
            let inputTextFieldView = PrimerGenericFieldView()
            inputTextFieldView.delegate = textFieldsDelegate
            inputTextFieldView.translatesAutoresizingMaskIntoConstraints = false
            inputTextFieldView.heightAnchor.constraint(equalToConstant: 35).isActive = true
            inputTextFieldView.textField.keyboardType = input.keyboardType ?? .default
            inputTextFieldView.allowedCharacterSet = input.allowedCharacterSet
            inputTextFieldView.maxCharactersAllowed = input.maxCharactersAllowed
            inputTextFieldView.isValid = input.isValid
            inputTextFieldView.shouldMaskText = false
            input.primerTextFieldView = inputTextFieldView
            
            let inputContainerView = PrimerCustomFieldView()
            inputContainerView.fieldView = inputTextFieldView
            inputContainerView.placeholderText = input.topPlaceholder
            inputContainerView.setup()
            inputContainerView.tintColor = .systemBlue
            inputStackView.addArrangedSubview(inputContainerView)
            
            if let descriptor = input.descriptor {
                let lbl = UILabel()
                lbl.font = UIFont.systemFont(ofSize: 12)
                lbl.translatesAutoresizingMaskIntoConstraints = false
                lbl.text = descriptor
                inputStackView.addArrangedSubview(lbl)
            }
            
            if self.paymentMethodConfiguration.type == PrimerPaymentMethodType.adyenMBWay.rawValue {
                let phoneNumberLabelStackView = UIStackView()
                phoneNumberLabelStackView.spacing = 2
                phoneNumberLabelStackView.axis = .vertical
                phoneNumberLabelStackView.alignment = .fill
                phoneNumberLabelStackView.distribution = .fill
                phoneNumberLabelStackView.addArrangedSubview(mbwayTopLabelView)
                inputTextFieldView.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
                stackViews.insert(phoneNumberLabelStackView, at: 0)
                stackView.addArrangedSubview(prefixSelectorButton)
            }
            
            stackView.addArrangedSubview(inputStackView)
            stackViews.append(stackView)
        }
        
        return stackViews
    }
}

extension InputAndResultUserInterfaceModule {
    
    internal func autofocusToNextFieldIfNeeded(for primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        if isValid == true {
            if primerTextFieldView is PrimerCardNumberFieldView {
                _ = expiryDateField.becomeFirstResponder()
            } else if primerTextFieldView is PrimerExpiryDateFieldView {
                _ = cardholderNameField?.becomeFirstResponder()
            }
        }
    }
}

extension InputAndResultUserInterfaceModule: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table View delegate methods
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? HeaderFooterLabelView
        header?.configure(text: Strings.PrimerTest.headerViewText)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        updateButtonUI()
        let stackView = UIStackView(arrangedSubviews: [self.submitButton!])
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let lastSelectedIndexPath = lastSelectedIndexPath {
            tableView.deselectRow(at: lastSelectedIndexPath, animated: true)
        }
        lastSelectedIndexPath = indexPath
        decisionSelectionCompletion?(decisions[indexPath.row])
//        enableSubmitButtonIfNeeded()
    }
    
    
    // MARK: - Table View data source methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return decisions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let decision = decisions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "FlowDecisionTableViewCell", for: indexPath) as! FlowDecisionTableViewCell
        cell.configure(decision: decision)
        return cell
    }
}


#endif
