import Foundation
import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class ResultScreenViewModel: ObservableObject {
    private let coordinator: CheckoutCoordinator

    init(coordinator: CheckoutCoordinator) {
        self.coordinator = coordinator
    }

    func complete() {
        // Handle successful completion
        coordinator.resetToRoot()
        // Maybe dismiss the entire checkout flow
    }

    func retry() {
        // Go back to payment methods list
        coordinator.resetToRoot()
        coordinator.navigate(to: .paymentMethodsList)
    }

    func cancel() {
        // Cancel the entire flow
        coordinator.resetToRoot()
        // Maybe dismiss the entire checkout flow
    }

    static func create(container: ContainerProtocol) async throws -> ResultScreenViewModel {
        let coordinator = try await container.resolve(CheckoutCoordinator.self)
        return ResultScreenViewModel(coordinator: coordinator)
    }
}
