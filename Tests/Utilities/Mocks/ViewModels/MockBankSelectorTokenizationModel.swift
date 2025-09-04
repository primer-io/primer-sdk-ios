@testable import PrimerSDK

final class MockBankSelectorTokenizationModel: BankSelectorTokenizationProviding {
    static let bankNameToBeFiltered = "Bank filtered"

    var didFinishPayment: ((Error?) -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    var didCancel: (() -> Void)?

    var paymentMethodType: PrimerPaymentMethodType
    var didCallFilter: Bool = false
    var didCallCancel: Bool = false
    var useSuccess: Bool = false

    let mockBanks: [AdyenBank] = [
        AdyenBank(id: "0", name: "Bank_0", iconUrlStr: nil, disabled: false),
        AdyenBank(id: "1", name: "Bank_1", iconUrlStr: nil, disabled: false),
        AdyenBank(id: "2", name: MockBankSelectorTokenizationModel.bankNameToBeFiltered, iconUrlStr: nil, disabled: false)
    ]

    init(paymentMethodType: PrimerPaymentMethodType) {
        self.paymentMethodType = paymentMethodType
    }


    func validate() async throws {}


    func retrieveListOfBanks() async throws -> [AdyenBank] {
        try await validate()
        return mockBanks
    }


    func filterBanks(query: String) -> [AdyenBank] {
        didCallFilter = true
        return [mockBanks[2]]
    }


    func tokenize(bankId: String) async throws {
        guard useSuccess else {
            throw PrimerError.failedToCreatePayment(
                paymentMethodType: paymentMethodType.rawValue,
                description: "payment_failed"
            )
        }
    }


    func handlePaymentMethodTokenData() async throws {}

    func setupNotificationObservers() {}

    func cancel() {
        didCallCancel = true
    }

    func cleanup() {}
}
