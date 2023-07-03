//
//  PrimerWebRedirectUIModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/6/23.
//

#if canImport(UIKit)

import Foundation
import SafariServices
import UIKit

class PrimerWebRedirectUIModule: PrimerPaymentMethodUIModule {
    
    var redirectUrl: URL!
    private var redirectUrlComponents: URLComponents?
    private var resumeToken: String!
    private var webViewController: SFSafariViewController?
    
    override func presentPaymentUI() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.webViewController = SFSafariViewController(url: self.redirectUrl)
                self.webViewController?.delegate = self
                
//                self.willPresentPaymentMethodUI?()
                
                self.redirectUrlComponents = URLComponents(string: self.redirectUrl.absoluteString)
                self.redirectUrlComponents?.query = nil
                
//                let presentEvent = Analytics.Event(
//                    eventType: .ui,
//                    properties: UIEventProperties(
//                        action: .present,
//                        context: Analytics.Event.Property.Context(
//                            paymentMethodType: self.config.type,
//                            url: self.redirectUrlComponents?.url?.absoluteString),
//                        extra: nil,
//                        objectType: .button,
//                        objectId: nil,
//                        objectClass: "\(Self.self)",
//                        place: .webview))
//
//                self.redirectUrlRequestId = UUID().uuidString
//
//                let networkEvent = Analytics.Event(
//                    eventType: .networkCall,
//                    properties: NetworkCallEventProperties(
//                        callType: .requestStart,
//                        id: self.redirectUrlRequestId!,
//                        url: self.redirectUrlComponents?.url?.absoluteString ?? "",
//                        method: .get,
//                        errorBody: nil,
//                        responseCode: nil))
//
//                Analytics.Service.record(events: [presentEvent, networkEvent])
                
                PrimerUIManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                    DispatchQueue.main.async {
//                        let viewEvent = Analytics.Event(
//                            eventType: .ui,
//                            properties: UIEventProperties(
//                                action: .view,
//                                context: Analytics.Event.Property.Context(
//                                    paymentMethodType: self.config.type,
//                                    url: self.redirectUrlComponents?.url?.absoluteString ?? ""),
//                                extra: nil,
//                                objectType: .button,
//                                objectId: nil,
//                                objectClass: "\(Self.self)",
//                                place: .webview))
//                        Analytics.Service.record(events: [viewEvent])
                        
                        PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.paymentMethodOrchestrator.paymentMethodConfig.type)
//                        self.didPresentPaymentMethodUI?()
                        seal.fulfill(())
                    }
                })
            }
        }
    }
    
    override func dismissPaymentUI() -> Promise<Void> {
        return Promise { seal in
            self.webViewController?.dismiss(animated: true, completion: { [weak self] in
                seal.fulfill()
            })
        }
    }
}

extension PrimerWebRedirectUIModule: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
//        let messageEvent = Analytics.Event(
//            eventType: .message,
//            properties: MessageEventProperties(
//                message: "safariViewControllerDidFinish called",
//                messageType: .other,
//                severity: .debug))
//        Analytics.Service.record(events: [messageEvent])
//
//        self.cancel()
    }
    
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
//        if didLoadSuccessfully {
//            self.didPresentPaymentMethodUI?()
//        }
//
//        if let redirectUrlRequestId = self.redirectUrlRequestId,
//           let redirectUrlComponents = self.redirectUrlComponents {
//            let networkEvent = Analytics.Event(
//                eventType: .networkCall,
//                properties: NetworkCallEventProperties(
//                    callType: .requestEnd,
//                    id: redirectUrlRequestId,
//                    url: redirectUrlComponents.url?.absoluteString ?? "",
//                    method: .get,
//                    errorBody: "didLoadSuccessfully: \(didLoadSuccessfully)",
//                    responseCode: nil))
//
//            Analytics.Service.record(events: [networkEvent])
//        }
    }
    
    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        if var safariRedirectComponents = URLComponents(string: URL.absoluteString) {
            safariRedirectComponents.query = nil
            
//            let messageEvent = Analytics.Event(
//                eventType: .message,
//                properties: MessageEventProperties(
//                    message: "safariViewController(_:initialLoadDidRedirectTo: \(safariRedirectComponents.url?.absoluteString ?? "n/a")) called",
//                    messageType: .other,
//                    severity: .debug))
//            Analytics.Service.record(events: [messageEvent])
        }
        
        if URL.absoluteString.hasSuffix("primer.io/static/loading.html") || URL.absoluteString.hasSuffix("primer.io/static/loading-spinner.html") {
            self.webViewController?.dismiss(animated: true)
//            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
        }
    }
}

#endif
