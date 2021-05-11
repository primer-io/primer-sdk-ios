#if canImport(UIKit)

import PassKit

extension ApplePayViewController: PKPaymentAuthorizationViewControllerDelegate {

    func onApplePayButtonPressed() {
        let viewModel: ApplePayViewModelProtocol = DependencyContainer.resolve()
        guard let amount = viewModel.amount else { return }
        
        let paymentItem = PKPaymentSummaryItem.init(
            label: "Primer Store",
            amount: NSDecimalNumber(value: amount / 100)
        )

        let paymentNetworks = [PKPaymentNetwork.amex, .discover, .masterCard, .visa]

        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {

            guard let countryCode = viewModel.countryCode else { return }
            guard let merchantIdentifier = viewModel.merchantIdentifier else { return }
            guard let currency = viewModel.currency else { return }

            let request = PKPaymentRequest()
            request.currencyCode = currency.rawValue
            request.countryCode = countryCode.rawValue
            request.merchantIdentifier = merchantIdentifier
            request.merchantCapabilities = PKMerchantCapability.capability3DS
            request.supportedNetworks = paymentNetworks
            request.paymentSummaryItems = [paymentItem]

            guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                displayDefaultAlert(title: "Error", message: "Unable to present Apple Pay authorization.")
                return
            }
            paymentVC.delegate = self
            self.present(paymentVC, animated: true, completion: nil)
        } else {
            displayDefaultAlert(title: "Error", message: "Unable to make Apple Pay transaction.")
        }
    }

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        dismiss(animated: true, completion: {
            self.dismiss(animated: true, completion: nil)
        })
    }

    private func createPaymentInstrument(with payment: PKPayment) -> PaymentInstrument? {
        do {
            let paymentData = try JSONDecoder().decode(ApplePayTokenPaymentData.self, from: payment.token.paymentData)

            guard let network = payment.token.paymentMethod.network else { return nil }
            
            let viewModel: ApplePayViewModelProtocol = DependencyContainer.resolve()
            guard let merchantIdentifier = viewModel.merchantIdentifier else { return nil }

            let method = ApplePayTokenPaymentMethod(
                displayName: payment.token.paymentMethod.displayName!,
                network: network.rawValue,
                type: "\(payment.token.paymentMethod.type.rawValue)"
            )

            let token = ApplePayToken(
                paymentData: paymentData,
                paymentMethod: method,
                transactionIdentifier: payment.token.transactionIdentifier
            )

            let instrument = PaymentInstrument(
                paymentMethodConfigId: viewModel.applePayConfigId,
                token: token,
                merchantIdentifier: merchantIdentifier
            )

            return instrument
        } catch {
            return nil
        }
    }

    @available(iOS 11.0, *)
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {

        guard let instrument = createPaymentInstrument(with: payment) else { return }
        
        let viewModel: ApplePayViewModelProtocol = DependencyContainer.resolve()

        viewModel.tokenize(
            instrument: instrument,
            completion: { error in
//                DispatchQueue.main.async {
//                    var alert: AlertController
//
//                    if let error = error {
//                        alert = AlertController(title: "Error!", message: error.localizedDescription, preferredStyle: .alert)
//                    } else {
//                        alert = AlertController(title: "Success!", message: "Purchase completed.", preferredStyle: .alert)
//                    }
//
//                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: { _ in
//                        self.dismiss(animated: true, completion: nil)
//                    }))
//
//                    alert.show()
//                }
            }
        )
    }
}

#endif
