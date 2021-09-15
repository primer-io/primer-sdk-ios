//
//  Dynamic3DSViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 15/9/21.
//

import Foundation

internal class Dynamic3DSViewModel {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    private var resumeHandlerDelegate: ResumeHandlerProtocol!
    
    init() {
        resumeHandlerDelegate = self
    }
    
    internal func receivedPaymentResponse(_ paymentResponse: PaymentResponseProtocol, for paymentMethodToken: PaymentMethodToken) {
        guard let clientToken = paymentResponse.requiredAction?.clientToken else {
            let err = PaymentException.missingClientToken
            Primer.shared.delegate?.onResumeError?(err, resumeHandler: self)
            return
        }
        
        if case .threeDSAuthentication = paymentResponse.requiredAction?.name {
            switch paymentResponse.status {
            case .pending:
                let state: AppStateProtocol = DependencyContainer.resolve()
                
                try? Primer.shared.refreshClientToken(clientToken)
                
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(paymentMethodToken: paymentMethodToken, protocolVersion: state.decodedClientToken?.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        Primer.shared.delegate?.onResumeSuccess?(paymentMethodToken.token!, resumeHandler: self)
                        
                    case .failure(let err):
                        log(logLevel: .error, message: "Failed to perform 3DS with error \(err as NSError)")
                        Primer.shared.delegate?.onResumeError?(PrimerError.threeDSFailed, resumeHandler: self)
                    }
                }
                
            case .failed:
                Primer.shared.delegate?.onResumeError?(PrimerError.threeDSFailed, resumeHandler: self)
                
            default:
                Primer.shared.delegate?.onResumeSuccess?(paymentMethodToken.token!, resumeHandler: self)
            }
            
        } else {
            Primer.shared.delegate?.onResumeSuccess?(paymentMethodToken.token!, resumeHandler: self)
        }
    }
        
    internal func navigate(withResult result: Result<String?, Error>) {
        DispatchQueue.main.async {
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            let router: RouterDelegate = DependencyContainer.resolve()
            switch result {
            case .failure(let err):
                
                let router: RouterDelegate = DependencyContainer.resolve()
                if settings.hasDisabledSuccessScreen {
                    Primer.shared.delegate?.checkoutFailed?(with: err)
                    router.root?.onDisabledSuccessScreenDismiss()
                } else {
                    router.show(.error(error: err))
                }

            case .success:
                if settings.hasDisabledSuccessScreen {
                    router.root?.onDisabledSuccessScreenDismiss()
                } else {
                    // The message from .success(String) could be passed as a a success message
                    router.show(.success(type: .regular))
                }
                
            }
        }

    }
    
}

extension Dynamic3DSViewModel: ResumeHandlerProtocol {
    func resume(withError error: Error) {
        navigate(withResult: .failure(error))
    }
    
    func resume(withClientToken clientToken: String? = nil) {
        if let clientToken = clientToken, let decodedClientToken = clientToken.jwtTokenPayload {
            let state: AppStateProtocol = DependencyContainer.resolve()
            state.accessToken = clientToken
            state.decodedClientToken = decodedClientToken
        }
        
        navigate(withResult: .success(nil))
    }
}
