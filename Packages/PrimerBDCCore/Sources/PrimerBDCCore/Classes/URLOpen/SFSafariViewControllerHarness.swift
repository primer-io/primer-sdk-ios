//
//  SFSafariViewControllerHarness.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerStepResolver
import SafariServices

@MainActor
final class SFSafariViewControllerHarness: NSObject, StepResolver {

    private let logger = Logger()
    private var safariViewController: SFSafariViewController?
    private var continuation: CheckedContinuation<StepResolutionResult, Never>?
    
    override init() {
        super.init()
        registerForNotifications()
    }
    
    func resolve(_ step: CodableValue) async throws -> StepResolutionResult {
        let browserStep = try step.casted(to: URLOpenParams.self)

        guard let url = URL(string: browserStep.url), open(url) else {
            logger.error("Could not present Safari for \(browserStep.url)")
            return StepResolutionResult(outcome: .error)
        }
        
        return await withCheckedContinuation { continuation = $0 }
    }

    private func resume(with outcome: TerminalOutcome) {
        continuation?.resume(returning: StepResolutionResult(outcome: outcome))
        continuation = nil
    }

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: .receivedUrlSchemeRedirect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: .receivedUrlSchemeCancellation,
            object: nil
        )
    }

    @objc private func handleNotification(_ notification: Notification) {
        switch notification.name {
        case .receivedUrlSchemeCancellation:
            resume(with: .cancelled)
        case .receivedUrlSchemeRedirect:
            safariViewController?.dismiss(animated: true)
            resume(with: .success)
        default: break
        }
    }

    @discardableResult
    private func open(_ url: URL) -> Bool {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let window = windowScene.windows.first(where: \.isKeyWindow),
            let rootVC = window.rootViewController else {
            return false
        }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = self
        safariVC.modalPresentationStyle = .overFullScreen
        topVC.present(safariVC, animated: true)
        safariViewController = safariVC
        return true
    }
}

extension SFSafariViewControllerHarness: @preconcurrency SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        resume(with: .cancelled)
    }
}

private struct URLOpenParams: Decodable {
    fileprivate let url: String
}

private extension Notification.Name {
    static let receivedUrlSchemeRedirect = Notification.Name(rawValue: "PrimerURLSchemeRedirect")
    static let receivedUrlSchemeCancellation = Notification.Name(rawValue: "PrimerURLSchemeCancellation")
}
