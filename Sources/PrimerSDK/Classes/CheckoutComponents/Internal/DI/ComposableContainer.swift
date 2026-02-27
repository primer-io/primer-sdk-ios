//
//  ComposableContainer.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// The main DI container for CheckoutComponents module.
/// Registers all dependencies needed for the checkout flow.
@available(iOS 15.0, *)
final class ComposableContainer: LogReporter {

  private let container: Container
  private let settings: PrimerSettings
  private let theme: PrimerCheckoutTheme

  init(
    settings: PrimerSettings,
    theme: PrimerCheckoutTheme = PrimerCheckoutTheme()
  ) {
    container = Container()
    self.settings = settings
    self.theme = theme
  }

  func configure() async {
    await registerInfrastructure()
    await registerValidation()
    await registerInteractors()
    await registerPaymentInteractors()
    await registerData()
    await registerLogging()

    await DIContainer.setContainer(container)

    #if DEBUG
      await performHealthCheck()
    #endif
  }

  var diContainer: Container {
    container
  }
}

// MARK: - Registration Helpers

@available(iOS 15.0, *)
extension ComposableContainer {

  /// Safely registers a dependency, logging errors instead of silently swallowing them.
  fileprivate func safeRegister<T>(
    _ type: T.Type,
    _ registration: () async throws -> Void
  ) async {
    do {
      try await registration()
    } catch {
      logger.error(message: "Failed to register \(type): \(error)")
    }
  }
}

// MARK: - Registration Methods

@available(iOS 15.0, *)
extension ComposableContainer {

  fileprivate func registerInfrastructure() async {
    await safeRegister(PrimerSettings.self) {
      _ = try await container.register(PrimerSettings.self)
        .asSingleton()
        .with { _ in self.settings }
    }

    await safeRegister(PrimerCheckoutTheme.self) {
      _ = try await container.register(PrimerCheckoutTheme.self)
        .asSingleton()
        .with { _ in self.theme }
    }

    await safeRegister(DesignTokensManager.self) {
      _ = try await container.register(DesignTokensManager.self)
        .asSingleton()
        .with { _ in DesignTokensManager() }
    }

    await safeRegister(CheckoutComponentsAnalyticsServiceProtocol.self) {
      _ = try await container.register(CheckoutComponentsAnalyticsServiceProtocol.self)
        .asSingleton()
        .with { _ in
          AnalyticsEventService.create(
            environmentProvider: AnalyticsEnvironmentProvider()
          )
        }
    }

    await safeRegister(CheckoutComponentsAnalyticsInteractorProtocol.self) {
      _ = try await container.register(CheckoutComponentsAnalyticsInteractorProtocol.self)
        .asSingleton()
        .with { resolver in
          DefaultAnalyticsInteractor(
            eventService: try await resolver.resolve(CheckoutComponentsAnalyticsServiceProtocol.self)
          )
        }
    }

    await safeRegister(AccessibilityAnnouncementService.self) {
      _ = try await container.register(AccessibilityAnnouncementService.self)
        .asSingleton()
        .with { _ in DefaultAccessibilityAnnouncementService() }
    }

    await safeRegister(ConfigurationService.self) {
      _ = try await container.register(ConfigurationService.self)
        .asSingleton()
        .with { _ in DefaultConfigurationService() }
    }
  }

  fileprivate func registerValidation() async {
    await safeRegister(RulesFactory.self) {
      _ = try await container.register(RulesFactory.self)
        .asSingleton()
        .with { _ in DefaultRulesFactory() }
    }

    await safeRegister(ValidationService.self) {
      _ = try await container.register(ValidationService.self)
        .asSingleton()
        .with { resolver in
          let factory = try await resolver.resolve(RulesFactory.self)
          return DefaultValidationService(rulesFactory: factory)
        }
    }
  }

  fileprivate func registerInteractors() async {
    await safeRegister(GetPaymentMethodsInteractor.self) {
      _ = try await container.register(GetPaymentMethodsInteractor.self)
        .asTransient()
        .with { resolver in
          GetPaymentMethodsInteractorImpl(
            repository: try await resolver.resolve(HeadlessRepository.self)
          )
        }
    }

    await safeRegister(ProcessCardPaymentInteractor.self) {
      _ = try await container.register(ProcessCardPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessCardPaymentInteractorImpl(
            repository: try await resolver.resolve(HeadlessRepository.self)
          )
        }
    }

    await safeRegister(ValidateInputInteractor.self) {
      _ = try await container.register(ValidateInputInteractor.self)
        .asTransient()
        .with { resolver in
          ValidateInputInteractorImpl(
            validationService: try await resolver.resolve(ValidationService.self)
          )
        }
    }

    await safeRegister(CardNetworkDetectionInteractor.self) {
      _ = try await container.register(CardNetworkDetectionInteractor.self)
        .asTransient()
        .with { resolver in
          CardNetworkDetectionInteractorImpl(
            repository: try await resolver.resolve(HeadlessRepository.self)
          )
        }
    }

    await safeRegister(SubmitVaultedPaymentInteractor.self) {
      _ = try await container.register(SubmitVaultedPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          SubmitVaultedPaymentInteractorImpl(
            repository: try await resolver.resolve(HeadlessRepository.self)
          )
        }
    }
  }

  fileprivate func registerPaymentInteractors() async {
    await safeRegister(ProcessPayPalPaymentInteractor.self) {
      _ = try await container.register(ProcessPayPalPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessPayPalPaymentInteractorImpl(
            repository: try await resolver.resolve(PayPalRepository.self)
          )
        }
    }

    await safeRegister(ProcessKlarnaPaymentInteractor.self) {
      _ = try await container.register(ProcessKlarnaPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessKlarnaPaymentInteractorImpl(
            repository: try await resolver.resolve(KlarnaRepository.self)
          )
        }
    }

    await safeRegister(ProcessWebRedirectPaymentInteractor.self) {
      _ = try await container.register(ProcessWebRedirectPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessWebRedirectPaymentInteractorImpl(
            repository: try await resolver.resolve(WebRedirectRepository.self)
          )
        }
    }

    await safeRegister(ProcessApplePayPaymentInteractor.self) {
      _ = try await container.register(ProcessApplePayPaymentInteractor.self)
        .asTransient()
        .with { _ in
          ProcessApplePayPaymentInteractorImpl(
            tokenizationService: TokenizationService(),
            createPaymentService: CreateResumePaymentService(
              paymentMethodType: PrimerPaymentMethodType.applePay.rawValue)
          )
        }
    }

    await safeRegister(ProcessAchPaymentInteractor.self) {
      _ = try await container.register(ProcessAchPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessAchPaymentInteractorImpl(
            repository: try await resolver.resolve(AchRepository.self)
          )
        }
    }

    await safeRegister(ProcessFormRedirectPaymentInteractor.self) {
      _ = try await container.register(ProcessFormRedirectPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessFormRedirectPaymentInteractorImpl(
            formRedirectRepository: try await resolver.resolve(FormRedirectRepository.self)
          )
        }
    }
  }

  fileprivate func registerData() async {
    // HeadlessRepository uses transient scope to ensure each checkout session gets a fresh instance.
    // This prevents stale state (e.g., cached card networks, validation handlers) from leaking
    // between checkout sessions when the user dismisses and re-presents the checkout UI.
    // Note: VaultManager is lazily initialized within HeadlessRepositoryImpl for vault payments.
    await safeRegister(HeadlessRepository.self) {
      _ = try await container.register(HeadlessRepository.self)
        .asTransient()
        .with { _ in HeadlessRepositoryImpl() }
    }

    await safeRegister(PaymentMethodMapper.self) {
      _ = try await container.register(PaymentMethodMapper.self)
        .asSingleton()
        .with { container in
          let configService = try await container.resolve(ConfigurationService.self)
          return PaymentMethodMapperImpl(configurationService: configService)
        }
    }

    await safeRegister(PayPalRepository.self) {
      _ = try await container.register(PayPalRepository.self)
        .asTransient()
        .with { _ in PayPalRepositoryImpl() }
    }

    await safeRegister(KlarnaRepository.self) {
      _ = try await container.register(KlarnaRepository.self)
        .asTransient()
        .with { _ in KlarnaRepositoryImpl() }
    }

    await safeRegister(AchRepository.self) {
      _ = try await container.register(AchRepository.self)
        .asTransient()
        .with { _ in AchRepositoryImpl() }
    }

    await safeRegister(WebRedirectRepository.self) {
      _ = try await container.register(WebRedirectRepository.self)
        .asTransient()
        .with { _ in WebRedirectRepositoryImpl() }
    }

    await safeRegister(FormRedirectRepository.self) {
      _ = try await container.register(FormRedirectRepository.self)
        .asTransient()
        .with { _ in FormRedirectRepositoryImpl() }
    }

    await safeRegister(QRCodeRepository.self) {
      _ = try await container.register(QRCodeRepository.self)
        .asTransient()
        .with { _ in QRCodeRepositoryImpl() }
    }
  }

  fileprivate func registerLogging() async {
    await safeRegister(LogNetworkClient.self) {
      _ = try await container.register(LogNetworkClient.self)
        .asSingleton()
        .with { _ in LogNetworkClient() }
    }

    await safeRegister(SensitiveDataMasker.self) {
      _ = try await container.register(SensitiveDataMasker.self)
        .asSingleton()
        .with { _ in SensitiveDataMasker() }
    }

    await safeRegister(LogPayloadBuilding.self) {
      _ = try await container.register(LogPayloadBuilding.self)
        .asSingleton()
        .with { _ in LogPayloadBuilder() }
    }

    await safeRegister(LoggingService.self) {
      _ = try await container.register(LoggingService.self)
        .asSingleton()
        .with { resolver in
          LoggingService(
            networkClient: try await resolver.resolve(LogNetworkClient.self),
            payloadBuilder: try await resolver.resolve(LogPayloadBuilding.self),
            masker: try await resolver.resolve(SensitiveDataMasker.self)
          )
        }
    }
  }

  #if DEBUG
    fileprivate func performHealthCheck() async {
      let diagnostics = await container.getDiagnostics()
      logger.debug(
        message:
          "Container diagnostics - Total registrations: \(diagnostics.totalRegistrations), Singletons: \(diagnostics.singletonInstances), Weak refs: \(diagnostics.weakReferences)/\(diagnostics.activeWeakReferences)"
      )

      let healthReport = await container.performHealthCheck()
      if healthReport.status == .healthy {
        logger.debug(message: "Container is healthy")
      } else {
        logger.warn(message: "Health issues: \(healthReport.issues)")
      }
    }
  #endif
}
