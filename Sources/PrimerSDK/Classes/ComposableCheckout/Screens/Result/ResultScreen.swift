import SwiftUI

@available(iOS 15.0, *)
struct ResultScreen: View {
    @StateObject private var viewModel: ResultScreenViewModel
    @Environment(\.designTokens) private var tokens

    let result: Result<CheckoutPaymentResult, CheckoutPaymentError>

    init(result: Result<CheckoutPaymentResult, CheckoutPaymentError>, viewModel: ResultScreenViewModel) {
        self.result = result
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Result icon
            resultIcon

            // Result message
            resultMessage

            // Result details
            resultDetails

            Spacer()

            // Action buttons
            actionButtons
        }
        .padding(24)
        .background(tokens?.primerColorBackground ?? .white)
        .navigationBarHidden(true)
    }

    private var resultIcon: some View {
        Group {
            switch result {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failure:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .font(.system(size: 60))
    }

    private var resultMessage: some View {
        Group {
            switch result {
            case .success:
                Text("Payment Successful!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            case .failure:
                Text("Payment Failed")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
        }
    }

    private var resultDetails: some View {
        Group {
            switch result {
            case .success(let paymentResult):
                VStack(spacing: 8) {
                    Text("Payment ID: \(paymentResult.paymentId)")
                    Text("Amount: \(paymentResult.amount)")
                    Text("Method: \(paymentResult.method)")
                }
                .font(.body)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            case .failure(let error):
                VStack(spacing: 8) {
                    Text(error.message)
                        .font(.body)
                    if let details = error.details {
                        Text(details)
                            .font(.caption)
                    }
                }
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            switch result {
            case .success:
                Button("Done") {
                    viewModel.complete()
                }
                .buttonStyle(.borderedProminent)
            case .failure:
                Button("Try Again") {
                    viewModel.retry()
                }
                .buttonStyle(.borderedProminent)

                Button("Cancel") {
                    viewModel.cancel()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    static func create(result: Result<CheckoutPaymentResult, CheckoutPaymentError>, container: ContainerProtocol) async throws -> ResultScreen {
        let viewModel = try await ResultScreenViewModel.create(container: container)
        return ResultScreen(result: result, viewModel: viewModel)
    }
}
