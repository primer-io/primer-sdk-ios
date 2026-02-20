//
//  SFSafariViewControllerHarness.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerStepResolver
import SafariServices

protocol SFSafariViewControllerHarnessDelegate: AnyObject {
    func safariViewControllerHarnessDidCancel() async throws
    func safariViewControllerHarnessDidComplete() async throws
}
    
@MainActor
final class SFSafariViewControllerHarness: NSObject, StepResolver {
    
    weak var delegate: SFSafariViewControllerHarnessDelegate?
    
    private let logger = Logger()
    private var safariViewController: SFSafariViewController?
    
    override init() {
        super.init()
        registerForNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func resolve(_ step: CodableValue) async throws -> CodableValue? {
        let browserStep = try step.casted(to: URLOpenParams.self)
 
        guard let url = URL(string: browserStep.url) else {
            logger.error("Could not create URL from \(browserStep.url)")
            return nil
        }
        open(url)
        return nil
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
            handleCancel()
        case .receivedUrlSchemeRedirect:
            safariViewController?.dismiss(animated: true)
            handleComplete()
        default: break
        }
    }
    
    private func handleCancel() {
        Task { [weak self] in
            do { try await self?.delegate?.safariViewControllerHarnessDidCancel() }
            catch { self?.logger.error("SafariVC failed to cancel: \(error)") }
        }
    }
    
    private func handleComplete() {
        Task { [weak self] in
            do { try await self?.delegate?.safariViewControllerHarnessDidComplete() }
            catch { self?.logger.error("Safari VC Failed to complete: \(error)") }
        }
    }
    
    private func open(_ url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: \.isKeyWindow),
              let rootVC = window.rootViewController else {
            return
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
    }
}

extension SFSafariViewControllerHarness: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        handleCancel()
    }
}

private struct URLOpenParams: Decodable {
    fileprivate let url: String
}

private extension Notification.Name {
    static let receivedUrlSchemeRedirect = Notification.Name(rawValue: "PrimerURLSchemeRedirect")
    static let receivedUrlSchemeCancellation = Notification.Name(rawValue: "PrimerURLSchemeCancellation")
}
