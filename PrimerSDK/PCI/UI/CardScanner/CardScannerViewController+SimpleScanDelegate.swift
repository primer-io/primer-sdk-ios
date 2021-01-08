import CardScan

extension CardScannerViewController: SimpleScanDelegate {
    
    func userDidCancelSimple(_ scanViewController: SimpleScanViewController) {
        print("user cancelled 🤨")
        let details = PrimerCreditCardDetails(name: "J Doe", number: "4242424242424242", expiryMonth: "01", expiryYear: "2030")
        delegate?.setScannedCardDetails(with: details)
    }
    
    public func userDidScanCardSimple(_ scanViewController: SimpleScanViewController, creditCard: CreditCard) {
        print("scanned! 🥳:", creditCard)
        let details = PrimerCreditCardDetails(name: creditCard.name, number: creditCard.number, expiryMonth: creditCard.expiryMonth, expiryYear: creditCard.expiryYear)
        delegate?.setScannedCardDetails(with: details)
        dismiss(animated: true, completion: nil)
    }
}
