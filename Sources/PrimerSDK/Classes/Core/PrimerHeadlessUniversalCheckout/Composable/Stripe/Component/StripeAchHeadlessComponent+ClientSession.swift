//
//  StripeAchHeadlessComponent+ClientSession.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 29.04.2024.
//

import UIKit

// MARK: - Client session methods
extension StripeAchHeadlessComponent {
    /**
     * Retrieves and handles the user details from the client session using the tokenization component.
     *
     * This method initiates a request to fetch user details associated with the client session. Upon successful retrieval,
     * it updates the local session cache, notifies the delegate of the next step to collect additional user details, and
     * handles potential errors silently.
     */
    func getClientSessionUserDetails() {
        firstly {
            tokenizationComponent.getClientSessionUserDetails()
        }
        .done { stripeAchUserDetails in
            self.clientSessionUserDetails = stripeAchUserDetails
            let step = StripeAchStep.collectUserDetails(stripeAchUserDetails)
            self.stepDelegate?.didReceiveStep(step: step)
        }
        .catch { _ in }
    }

    /**
     * Evaluates if the client session needs to be updated with new user details and performs the appropriate actions.
     *
     * This method compares the current input user details with the details stored in the client session. If there is a
     * discrepancy, it updates the client session; otherwise, it continues with the tokenization process.
     */
    func patchClientSessionIfNeeded() {
        let shouldPatchUserDetails = StripeAchUserDetails.isEqual(lhs: inputUserDetails, rhs: clientSessionUserDetails)
        var clientSessionActions: [ClientSession.Action] = []

        if shouldPatchUserDetails.areEqual {
            startVMTokenization()
        } else {
            for differingField in shouldPatchUserDetails.differingFields {
                if let action = createAction(from: differingField) {
                    clientSessionActions.append(action)
                }
            }
            patchClientSession(actions: clientSessionActions)
        }
    }
}

// MARK: - Private helper methods
extension StripeAchHeadlessComponent {
    /**
     * Updates the client session with new user details through a series of set actions.
     *
     * - Parameters:
     *   - setFirstNameAction: An action to update the customer's first name.
     *   - setLastNameAction: An action to update the customer's last name.
     *   - setEmailAddressAction: An action to update the customer's email address.
     *
     * Upon assembling all required actions into a client session update request, this method sends the update.
     * If the session is successfully updated, it proceeds with the tokenization process;
     * if an error occurs, it informs the error delegate with detailed error information.
     */
    private func patchClientSession(actions: [ClientSession.Action]) {
        let clientSessionActionsRequest = ClientSessionUpdateRequest(
            actions: ClientSessionAction(
                actions: actions))

        firstly {
            tokenizationComponent.patchClientSession(actionsRequest: clientSessionActionsRequest)
        }
        .done { _ in
            self.startVMTokenization()
        }
        .catch { error in
            let primerError = PrimerError.failedToCreateSession(
                error: error,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )

            self.errorDelegate?.didReceiveError(error: primerError)
        }
    }

    /**
     * Initiates the tokenization process for the selected payment method configuration.
     *
     * This method filters the available payment method configurations to find the specific configuration for STRIPE_ACH.
     * If found, it triggers the start of the tokenization process in the corresponding view model and notifies the step delegate.
     */
    private func startVMTokenization() {
        guard let paymentMethodViewModel = PrimerAPIConfiguration.paymentMethodConfigViewModels
            .filter({ $0.config.type == "STRIPE_ACH" })
            .first as? StripeTokenizationViewModel else { return }
        
        paymentMethodViewModel.start()
        stepDelegate?.didReceiveStep(step: StripeAchStep.tokenizationStarted)
    }

    /**
     * Creates a specific action to update the client session based on the type of user details validation error.
     *
     * This method switches on the type of `StripeAchUserDetailsError` provided and returns an appropriate
     * `ClientSession.Action` to correct the user details. 
     * If the error type does not correspond to a specific action, it returns `nil`, indicating no action is required for the client session update.
     *
     * - Parameter validationError: The validation error encountered with user details.
     * - Returns: An optional `ClientSession.Action` to update the client session or `nil` if no update is necessary.
     */
    private func createAction(from validationError: StripeAchUserDetailsError) -> ClientSession.Action? {
        switch validationError {
        case .invalidFirstName:
            return ClientSession.Action.setCustomerFirstName(inputUserDetails.firstName)
        case .invalidLastName:
            return ClientSession.Action.setCustomerLastName(inputUserDetails.lastName)
        case .invalidEmailAddress:
            return ClientSession.Action.setCustomerEmailAddress(inputUserDetails.emailAddress)
        }
    }
}
