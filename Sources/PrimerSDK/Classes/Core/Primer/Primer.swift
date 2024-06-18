import UIKit

// swiftlint:disable identifier_name
#if DEBUG
private var __isRunningTests__: Bool = false

var TEST: Bool {
    #if DEBUG
    __isRunningTests__
    #else
    false
    #endif
}
#endif

private let _Primer: Primer = {
    #if DEBUG
    if ProcessInfo.processInfo.environment["UNIT_TESTS"] == "1" {
        __isRunningTests__ = true
    }
    #endif
    return Primer()
}()
// swiftlint:enable identifier_name

public class Primer {

    // MARK: - PROPERTIES

    public weak var delegate: PrimerDelegate? {
        didSet {
            PrimerInternal.shared.sdkIntegrationType = .dropIn
        }
    }
    public var intent: PrimerSessionIntent? {
        return PrimerInternal.shared.intent
    }
    public var selectedPaymentMethodType: String? {
        return PrimerInternal.shared.selectedPaymentMethodType
    }
    public var integrationOptions: PrimerIntegrationOptions?

    // MARK: - INITIALIZATION

    public static var shared: Primer {
        return _Primer
    }

    fileprivate init() {}

    public func application(_ app: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return PrimerInternal.shared.application(app, open: url, options: options)
    }

    public func application(_ application: UIApplication,
                            continue userActivity: NSUserActivity,
                            restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return PrimerInternal.shared.application(application,
                                                 continue: userActivity,
                                                 restorationHandler: restorationHandler)
    }

    // MARK: - CONFIGURATION

    /**
     Configure SDK's settings
     */

    public func configure(settings: PrimerSettings? = nil, delegate: PrimerDelegate? = nil) {
        self.delegate = delegate
        PrimerInternal.shared.configure(settings: settings)
    }

    // MARK: - PRESENTATION

    /**
     Show Primer Checkout
     */
    public func showUniversalCheckout(clientToken: String, completion: ((Error?) -> Void)? = nil) {
        PrimerInternal.shared.showUniversalCheckout(clientToken: clientToken, completion: completion)
    }

    /**
     Show Primer Vault Manager
     */
    public func showVaultManager(clientToken: String, completion: ((Error?) -> Void)? = nil) {
        PrimerInternal.shared.showVaultManager(clientToken: clientToken, completion: completion)
    }

    /**
     Show a payment method with the speicified intent (if applicable)
     */
    public func showPaymentMethod(_ paymentMethodType: String,
                                  intent: PrimerSessionIntent,
                                  clientToken: String,
                                  completion: ((Error?) -> Void)? = nil) {
        PrimerInternal.shared.sdkIntegrationType = .dropIn
        PrimerInternal.shared.showPaymentMethod(paymentMethodType,
                                                withIntent: intent,
                                                andClientToken: clientToken,
                                                completion: completion)
    }

    /**
     Dismiss Primer UI
     */
    public func dismiss() {
        PrimerInternal.shared.dismiss()
    }
}
