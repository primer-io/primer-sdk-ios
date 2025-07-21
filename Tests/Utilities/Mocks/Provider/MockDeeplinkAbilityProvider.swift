@testable import PrimerSDK
import Foundation

struct MockDeeplinkAbilityProvider: DeeplinkAbilityProviding {
    var isDeeplinkAvailable: Bool = true

    func canOpenURL(_ url: URL) -> Bool {
        return isDeeplinkAvailable
    }
}
