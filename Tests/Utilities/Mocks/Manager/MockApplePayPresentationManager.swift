import PassKit
@testable import PrimerSDK

final class MockApplePayPresentationManager: ApplePayPresenting {
    var isPresentable: Bool = true
    var errorForDisplay: Error = PrimerError.unableToPresentPaymentMethod(paymentMethodType: "APPLE_PAY")
    var onPresent: ((ApplePayRequest, PKPaymentAuthorizationControllerDelegate) -> Result<Void, Error>)?

    func present(withRequest applePayRequest: ApplePayRequest, delegate: PKPaymentAuthorizationControllerDelegate) -> Promise<Void> {
        switch onPresent?(applePayRequest, delegate) {
        case .success: .fulfilled(())
        case .failure(let error): .rejected(error)
        case nil: .rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        }
    }

    func present(withRequest applePayRequest: ApplePayRequest, delegate: any PKPaymentAuthorizationControllerDelegate) async throws {
        switch onPresent?(applePayRequest, delegate) {
        case .success: return
        case .failure(let error): throw error
        case nil: throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }
}
