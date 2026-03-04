//
//  MerchantHeadlessCheckoutRawDataViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import UIKit

class MerchantHeadlessCheckoutRawDataViewController: UIViewController {

    static func instantiate(paymentMethodType: String) -> MerchantHeadlessCheckoutRawDataViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantHUCRawDataViewController") as! MerchantHeadlessCheckoutRawDataViewController
        mpmvc.paymentMethodType = paymentMethodType
        return mpmvc
    }

    var primerRawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?

    var selectedCardIndex: Int = 0

    var stackView: UIStackView!
    var paymentMethodType: String!
    var paymentId: String?
    var activityIndicator: UIActivityIndicatorView?
    var rawCardData = PrimerCardData(cardNumber: "",
                                     expiryDate: "",
                                     cvv: "",
                                     cardholderName: "")

    var cardnumberTextField: UITextField?
    var expiryDateTextField: UITextField?
    var cvvTextField: UITextField?
    var cardholderNameTextField: UITextField?
    var payButton: UIButton!

    var cardsStackView: UIStackView!

    var logs: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true

        renderInputs()

        cardnumberTextField?.becomeFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideLoadingOverlay()
    }

    // 4111 1234 1234 1234
    // 5522 1234 1234 1234

    func renderAutoInputUI() {
        let stack = UIStackView()
        stack.axis = .horizontal

        let updateCardData = { [self] in
            rawCardData.cardNumber = cardnumberTextField!.text!.replacingOccurrences(of: " ", with: "")
            primerRawDataManager?.rawData = rawCardData
        }

        let visaButton = UIButton(primaryAction: UIAction(title: "VISA", handler: { _ in
            self.cardnumberTextField?.text = "4111 1234 1234 1234"
            updateCardData()
        }))
        let mcButton = UIButton(primaryAction: UIAction(title: "MasterCard", handler: { _ in
            self.cardnumberTextField?.text = "5522 1234 1234 1234"
            updateCardData()
        }))

        stack.addArrangedSubview(visaButton)
        stack.addArrangedSubview(mcButton)
        stack.distribution = .fillEqually

        stackView.addArrangedSubview(stack)
    }

    func renderInputs() {
        renderAutoInputUI()

        do {
            primerRawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethodType, delegate: self)
            let inputElementTypes = primerRawDataManager!.listRequiredInputElementTypes(for: paymentMethodType)

            for inputElementType in inputElementTypes {
                switch inputElementType {
                case .cardNumber:
                    cardnumberTextField = styledTextField(forAccessibilityId: "cardNumberTextField",
                                                               withPlaceholderText: "4242 4242 4242 4242")
                case .expiryDate:
                    expiryDateTextField = styledTextField(forAccessibilityId: "expiryDateTextField",
                                                               withPlaceholderText: "03/2030")
                case .cvv:
                    cvvTextField = styledTextField(forAccessibilityId: "cvvTextField",
                                                        withPlaceholderText: "123")
                case .cardholderName:
                    cardholderNameTextField = styledTextField(forAccessibilityId: "cardholderNameTextField",
                                                                   withPlaceholderText: "John Smith")
                case .otp:
                    break
                case .postalCode:
                    break
                case .phoneNumber:
                    break
                case .retailer:
                    break
                case .unknown:
                    break
                case .countryCode:
                    break
                case .firstName:
                    break
                case .lastName:
                    break
                case .addressLine1:
                    break
                case .addressLine2:
                    break
                case .city:
                    break
                case .state:
                    break
                case .all:
                    break
                case .email:
                    break
                }
            }

            payButton = UIButton(frame: .zero)
            stackView.addArrangedSubview(payButton)
            payButton.accessibilityIdentifier = "submit_btn"
            payButton.translatesAutoresizingMaskIntoConstraints = false
            payButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
            payButton.setTitle("Pay", for: .normal)
            payButton.titleLabel?.adjustsFontSizeToFitWidth = true
            payButton.titleLabel?.minimumScaleFactor = 0.7
            payButton.backgroundColor = .lightGray
            payButton.setTitleColor(.white, for: .normal)
            payButton.isEnabled = false
            payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)

            cardsStackView = UIStackView()
            cardsStackView.axis = .horizontal
            stackView.addArrangedSubview(cardsStackView)
            cardsStackView.translatesAutoresizingMaskIntoConstraints = false
            cardsStackView.spacing = 10
            cardsStackView.alignment = .center
            cardsStackView.distribution = .fillProportionally
            cardsStackView.accessibilityIdentifier = "cardNetworksSelectionView"

        } catch {
            print("[MerchantHeadlessCheckoutRawDataViewController] ERROR: Failed to set up card entry fields")
        }
    }

    private func styledTextField(forAccessibilityId accessibilityId: String,
                                 withPlaceholderText placeholderText: String) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.accessibilityIdentifier = accessibilityId
        textField.borderStyle = .none
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        textField.delegate = self
        textField.placeholder = placeholderText

        stackView.addArrangedSubview(textField)

        return textField
    }

    @IBAction func payButtonTapped(_ sender: UIButton) {
        guard expiryDateTextField?.text?.isEmpty == false,
              let expiryComponents = expiryDateTextField?.text?.split(separator: "/"),
              expiryComponents.count == 2,
              case let yearComponent = String(expiryComponents[1]),
              [2, 4].contains(yearComponent.count) else {
            return showErrorMessage("Please write expiry date in format MM/YY or MM/YYYY")
        }

        if paymentMethodType == "PAYMENT_CARD" {
            primerRawDataManager!.submit()
            showLoadingOverlay()
        }
    }

    // MARK: - HELPERS

    private func showLoadingOverlay() {
        DispatchQueue.main.async {
            self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
            self.view.addSubview(self.activityIndicator!)
            self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
            self.activityIndicator?.color = .black
            self.activityIndicator?.startAnimating()
        }
    }

    private func hideLoadingOverlay() {
        DispatchQueue.main.async {
            if let activityIndicator = self.activityIndicator, activityIndicator.isAnimating {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
                self.activityIndicator = nil
            }
        }
    }
}

extension MerchantHeadlessCheckoutRawDataViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text

        var newText: String = ""

        if text != nil,
           let textRange = Range(range, in: text!) {
            newText = text!.replacingCharacters(in: textRange, with: string)
        }

        if textField == cardnumberTextField {
            rawCardData = PrimerCardData(
                cardNumber: newText.replacingOccurrences(of: " ", with: ""),
                expiryDate: expiryDateTextField?.text ?? "",
                cvv: cvvTextField?.text ?? "",
                cardholderName: cardholderNameTextField?.text ?? "",
                cardNetwork: rawCardData.cardNetwork)

        } else if textField == expiryDateTextField {
            rawCardData = PrimerCardData(
                cardNumber: cardnumberTextField?.text ?? "",
                expiryDate: newText,
                cvv: cvvTextField?.text ?? "",
                cardholderName: cardholderNameTextField?.text ?? "",
                cardNetwork: rawCardData.cardNetwork)

        } else if textField == cvvTextField {
            rawCardData = PrimerCardData(
                cardNumber: cardnumberTextField?.text ?? "",
                expiryDate: expiryDateTextField?.text ?? "",
                cvv: newText,
                cardholderName: cardholderNameTextField?.text ?? "",
                cardNetwork: rawCardData.cardNetwork)

        } else if textField == cardholderNameTextField {
            rawCardData = PrimerCardData(
                cardNumber: cardnumberTextField?.text ?? "",
                expiryDate: expiryDateTextField?.text ?? "",
                cvv: cvvTextField?.text ?? "",
                cardholderName: newText.isEmpty ? nil : newText,
                cardNetwork: rawCardData.cardNetwork)
        }

        print("self.rawCardData\ncardNumber: \(rawCardData.cardNumber)\nexpiryDate: \(rawCardData.expiryDate)\ncvv: \(rawCardData.cvv)\ncardholderName: \(rawCardData.cardholderName ?? "nil")")
        primerRawDataManager?.rawData = rawCardData

        return true
    }
}

extension MerchantHeadlessCheckoutRawDataViewController: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              dataIsValid isValid: Bool,
                              errors: [Error]?) {
        print("\n\nMERCHANT APP\n\(#function)\ndataIsValid: \(isValid)")
        logs.append(#function)
        payButton.backgroundColor = isValid ? .black : .lightGray
        payButton.isEnabled = isValid
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              metadataDidChange metadata: [String: Any]?) {
        print("\n\nMERCHANT APP\n\(#function)\nmetadataDidChange: \(String(describing: metadata))")
        logs.append(#function)
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              willFetchMetadataForState state: PrimerValidationState) {
        print("[MerchantHeadlessCheckoutRawDataViewController] willFetchCardMetadataForState")
        DispatchQueue.main.async {
            self.cardsStackView.removeAllArrangedSubviews()
            let progressView = UIProgressView(progressViewStyle: .default)
            self.cardsStackView.addArrangedSubview(progressView)
        }
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didReceiveMetadata metadata: PrimerPaymentMethodMetadata, forState state: PrimerValidationState) {
        guard let metadata = metadata as? PrimerCardNumberEntryMetadata,
              let cardState = state as? PrimerCardNumberEntryState else {
            print("[MerchantHeadlessCheckoutRawDataViewController] ERROR: Failed to cast metadata and state to card entry models")
            return
        }

        let printableNetworks = metadata.detectedCardNetworks.items.map(\.network.rawValue).joined(separator: ", ")
        print("[MerchantHeadlessCheckoutRawDataViewController] didReceiveCardMetadata: \(printableNetworks) forCardValidationState: \(cardState.cardNumber)")

        DispatchQueue.main.async {
            self.cardsStackView.removeAllArrangedSubviews()

            (metadata.selectableCardNetworks ?? metadata.detectedCardNetworks).items.enumerated().forEach { (index, detectedNetwork) in
                let image = PrimerHeadlessUniversalCheckout.AssetsManager.getCardNetworkAsset(for: detectedNetwork.network)
                let imageView = UIImageView(image: image?.cardImage)
                imageView.isUserInteractionEnabled = true
                imageView.translatesAutoresizingMaskIntoConstraints = false

                let width: CGFloat = 112
                let height: CGFloat = 80

                imageView.heightAnchor.constraint(equalToConstant: width).isActive = true
                imageView.widthAnchor.constraint(equalToConstant: height).isActive = true
                imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor,
                                                 multiplier: width / height).isActive = true
                imageView.setContentHuggingPriority(.required, for: .horizontal)
                imageView.accessibilityIdentifier = detectedNetwork.displayName

                self.cardsStackView.addArrangedSubview(imageView)

                let tapGestureRecognizer = TapGestureRecognizer {
                    self.selectedCardIndex = index
                    if self.selectedCardIndex < metadata.detectedCardNetworks.items.count {
                        self.rawCardData.cardNetwork = metadata.detectedCardNetworks.items[self.selectedCardIndex].network
                    }
                    self.updateCardImages()
                }
                imageView.addGestureRecognizer(tapGestureRecognizer)
            }

            let emptyView = UIView()
            emptyView.translatesAutoresizingMaskIntoConstraints = false
            emptyView.heightAnchor.constraint(equalToConstant: 1).isActive = true
            emptyView.widthAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true
            self.cardsStackView.addArrangedSubview(emptyView)

            self.updateCardImages()

			self.rawCardData.cardNetwork = metadata.detectedCardNetworks.items[safe: self.selectedCardIndex]?.network
        }
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager,
                              didReceiveBinData binData: PrimerBinData) {
        let statusStr = binData.status == .complete ? "complete" : "partial"
        let preferredStr = binData.preferred?.displayName ?? "none"
        let alternativesStr = binData.alternatives.map(\.displayName).joined(separator: ", ")
        print("[MerchantHeadlessCheckoutRawDataViewController] didReceiveBinData - status: \(statusStr), preferred: \(preferredStr), alternatives: [\(alternativesStr)], firstDigits: \(binData.firstDigits ?? "nil")")

        if let preferred = binData.preferred {
            print("  Issuer: \(preferred.issuerName ?? "unknown"), Country: \(preferred.issuerCountryCode ?? "unknown"), Funding: \(preferred.accountFundingType ?? "unknown")")
        }
    }

    private func updateCardImages() {
        cardsStackView.arrangedSubviews.filter { $0 is UIImageView }.enumerated().forEach { (index, imageView) in
            imageView.layer.opacity = (index == self.selectedCardIndex) ? 1 : 0.5
            imageView.isUserInteractionEnabled = true
        }
    }
}
