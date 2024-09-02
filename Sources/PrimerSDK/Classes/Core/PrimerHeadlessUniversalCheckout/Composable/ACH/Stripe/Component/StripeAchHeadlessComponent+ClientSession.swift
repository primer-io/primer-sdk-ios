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
            clientSessionService.getClientSessionUserDetails()
        }
        .done { stripeAchUserDetails in
            self.clientSessionUserDetails = stripeAchUserDetails
            self.updateAndValidateSessionUserDetails()
            let step = ACHUserDetailsStep.retrievedUserDetails(stripeAchUserDetails)
            self.stepDelegate?.didReceiveStep(step: step)
        }
        .catch { _ in }
    }

    func setClientSessionActions() {
        firstly {
            let paymentMethodType = self.tokenizationViewModel.config.type
            let actionsRequest = self.clientSessionService.prepareClientSessionActionsRequestBody(paymentMethodType: paymentMethodType)
            return clientSessionService.patchClientSession(with: actionsRequest)
        }
        .done {}
        .catch { error in
            let primerError = PrimerError.failedToCreateSession(
                error: error,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            
            self.errorDelegate?.didReceiveError(error: primerError)
        }
    }

    private func updateAndValidateSessionUserDetails() {
        let sessionCollectableDataArray = [ACHUserDetailsCollectableData.firstName(clientSessionUserDetails.firstName),
                                           ACHUserDetailsCollectableData.lastName(clientSessionUserDetails.lastName),
                                           ACHUserDetailsCollectableData.emailAddress(clientSessionUserDetails.emailAddress)]

        sessionCollectableDataArray.forEach { collectableData in
            updateCollectedData(collectableData: collectableData)
        }
    }

    /**
     * Evaluates if the client session needs to be updated with new user details and performs the appropriate actions.
     *
     * This method compares the current input user details with the details stored in the client session. If there is a
     * discrepancy, it updates the client session; otherwise, it continues with the tokenization process.
     */
    func patchClientSessionIfNeeded() {
        let patchUserDetailsComparison = ACHUserDetails.compare(lhs: inputUserDetails, rhs: clientSessionUserDetails)
        var clientSessionActions: [ClientSession.Action] = []

        if patchUserDetailsComparison.areEqual {
            startVMTokenization()
        } else {
            for differingField in patchUserDetailsComparison.differingFields {
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
            clientSessionService.patchClientSession(with: clientSessionActionsRequest)
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
        if PrimerInternal.shared.sdkIntegrationType == .headless {
            tokenizationViewModel.start()
        }
        stepDelegate?.didReceiveStep(step: ACHUserDetailsStep.didCollectUserDetails)
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
    private func createAction(from validationError: ACHUserDetailsError) -> ClientSession.Action? {
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
