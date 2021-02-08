//
//  AnalyticsService.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 27/01/2021.
//
import Mixpanel

protocol AnalyticsServiceProtocol: class {
    func trackEvent(of type: AnalyticsEventType)
}

enum AnalyticsEventType: String {
    case LOADED_CHECKOUT_UI
    case STARTED_CHECKOUT
}

class AnalyticsService: AnalyticsServiceProtocol {
    func trackEvent(of type: AnalyticsEventType) {
        print(Mixpanel.mainInstance().serverURL)
        Mixpanel.mainInstance().track(event: type.rawValue)
        
    }
    
    init() {
        Mixpanel.initialize(token: "token", flushInterval: 0)
        Mixpanel.mainInstance().serverURL = "https://analytics.api.dev.core.primer.io/mixpanel"
//        Mixpanel.mainInstance().delegate = self
        Mixpanel.mainInstance().loggingEnabled = true
        Mixpanel.mainInstance().flush(completion: {
        })
    }
}

extension AnalyticsService: MixpanelDelegate {
    func mixpanelWillFlush(_ mixpanel: MixpanelInstance) -> Bool {
        print(mixpanel)
        return true
    }
}

@propertyWrapper
struct Dependency<T> {
    var wrappedValue: T

    init() {
        self.wrappedValue = DependencyContainer.resolve()
    }
}

final class DependencyContainer {
    private var dependencies = [String: AnyObject]()
    private static var shared = DependencyContainer()

    static func register<T>(_ dependency: T) {
        shared.register(dependency)
    }

    static func resolve<T>() -> T {
        shared.resolve()
    }
    
    static func clear() {
        shared.clear()
    }

    private func register<T>(_ dependency: T) {
        let key = String(describing: T.self)
        dependencies[key] = dependency as AnyObject
    }

    private func resolve<T>() -> T {
        let key = String(describing: T.self)
        let dependency = dependencies[key] as? T

        precondition(dependency != nil, "No dependency found for \(key)! must register a dependency before resolve.")

        return dependency!
    }
    
    private func clear() {
        dependencies = [String: AnyObject]()
    }
}
