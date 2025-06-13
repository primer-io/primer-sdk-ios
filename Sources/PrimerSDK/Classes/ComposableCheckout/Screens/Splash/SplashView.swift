import SwiftUI

@available(iOS 15.0, *)
struct SplashView: View {
    @StateObject private var viewModel: SplashViewModel
    @Environment(\.designTokens) private var tokens

    init(viewModel: SplashViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Loading spinner
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: tokens?.primerColorBrand ?? .blue))

            // Loading text
            Text("Initializing payment...")
                .font(.headline)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            // Subtitle
            Text("Please wait while we prepare your payment options")
                .font(.caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(tokens?.primerColorBackground ?? .white)
        .task {
            await viewModel.initialize()
        }
    }
}

// MARK: - Factory
@available(iOS 15.0, *)
extension SplashView {
    static func create(container: ContainerProtocol) async throws -> SplashView {
        let viewModel = try await SplashViewModel.create(container: container)
        return SplashView(viewModel: viewModel)
    }
}
