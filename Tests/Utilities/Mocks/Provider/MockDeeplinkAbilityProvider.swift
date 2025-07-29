import Foundation
@testable import PrimerSDK

struct MockDeeplinkAbilityProvider: DeeplinkAbilityProviding {
    var isDeeplinkAvailable = true

    func canOpenURL(_ url: URL) -> Bool {
        isDeeplinkAvailable
    }
}
