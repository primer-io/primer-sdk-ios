import CardScan

extension CardScannerViewController: SimpleScanDelegate {
    
    func userDidCancelSimple(_ scanViewController: SimpleScanViewController) {}
    
    public func userDidScanCardSimple(_ scanViewController: SimpleScanViewController, creditCard: CreditCard) {
        scanViewController.cancelScan()
        
        let details = PrimerCreditCardDetails(
            name: creditCard.name,
            number: creditCard.number,
            expiryMonth: creditCard.expiryMonth,
            expiryYear: creditCard.expiryYear
        )
        
        delegate?.setScannedCardDetails(with: details)
        router?.pop()
    }
}
