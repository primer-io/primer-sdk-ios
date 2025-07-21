@testable import PrimerSDK

final class MockBankSelectorTokenizationModel: BankSelectorTokenizationProviding {
    var didFinishPayment: ((Error?) -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    var didCancel: (() -> Void)?

    var paymentMethodType: PrimerPaymentMethodType
    var didCallFilter: Bool = false
    var didCallCancel: Bool = false
    var useSuccess: Bool = false
    static let bankNameToBeFiltered = "Bank filtered"
    init(paymentMethodType: PrimerPaymentMethodType) {
        self.paymentMethodType = paymentMethodType
    }

    let mockBanks: [AdyenBank] = [AdyenBank(id: "0", name: "Bank_0", iconUrlStr: nil, disabled: false),
                                  AdyenBank(id: "1", name: "Bank_1", iconUrlStr: nil, disabled: false),
                                  AdyenBank(id: "2", name: MockBankSelectorTokenizationModel.bankNameToBeFiltered, iconUrlStr: nil, disabled: false)]
    func validateReturningPromise() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    func validate() async throws {}

    func retrieveListOfBanks() -> Promise<[AdyenBank]> {
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .done {
                seal.fulfill(self.mockBanks)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func retrieveListOfBanks() async throws -> [AdyenBank] {
        try await validate()
        return mockBanks
    }

    private func fetchBanks() -> Promise<[AdyenBank]> {
        return Promise { seal in
            seal.fulfill(mockBanks)
        }
    }

    func filterBanks(query: String) -> [AdyenBank] {
        didCallFilter = true
        return [mockBanks[2]]
    }

    func tokenize(bankId: String) -> Promise<Void> {
        return Promise { seal in
            useSuccess ? seal.fulfill() : seal.reject(PrimerError.failedToCreatePayment(
                paymentMethodType: paymentMethodType.rawValue,
                description: "payment_failed"
            ))
        }
    }

    func tokenize(bankId: String) async throws {
        guard useSuccess else {
            throw PrimerError.failedToCreatePayment(
                paymentMethodType: paymentMethodType.rawValue,
                description: "payment_failed"
            )
        }
    }

    func handlePaymentMethodTokenData() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    func handlePaymentMethodTokenData() async throws {}

    func setupNotificationObservers() {}

    func cancel() {
        didCallCancel = true
    }

    func cleanup() {}
}
