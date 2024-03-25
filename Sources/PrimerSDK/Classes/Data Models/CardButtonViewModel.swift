import Foundation

struct CardButtonViewModel {

    let network, cardholder, last4, expiry: String
    let imageName: ImageName
    let paymentMethodType: PaymentInstrumentType
    var surCharge: Int? {
        let session = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
        guard let options = session?.paymentMethod?.options else { return nil }
        guard let paymentCardOption = options
                .filter({ $0["type"] as? String == PrimerPaymentMethodType.paymentCard.rawValue })
                .first else { return nil }
        guard let networks = paymentCardOption["networks"] as? [[String: Any]] else { return nil }
        guard let tmpNetwork = networks.filter({ ($0["type"] as? String)?
                                                .lowercased() == network.lowercased() })
                .first else { return nil }
        return tmpNetwork["surcharge"] as? Int
    }
}
