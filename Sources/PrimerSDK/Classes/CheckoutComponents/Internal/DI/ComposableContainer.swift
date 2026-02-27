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

    await registerDomain()

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

// MARK: - Registration Methods

@available(iOS 15.0, *)
extension ComposableContainer {

  fileprivate func registerInfrastructure() async {
    do {
      try await container.register(PrimerSettings.self)
        .asSingleton()
        .with { _ in self.settings }
    } catch {
      logger.error(message: "Failed to register PrimerSettings: \(error)")
    }

    do {
      try await container.register(PrimerCheckoutTheme.self)
        .asSingleton()
        .with { _ in self.theme }
    } catch {
      logger.error(message: "Failed to register PrimerCheckoutTheme: \(error)")
    }

    do {
      try await container.register(DesignTokensManager.self)
        .asSingleton()
        .with { _ in DesignTokensManager() }
    } catch {
      logger.error(message: "Failed to register DesignTokensManager: \(error)")
    }

    do {
      try await container.register(CheckoutComponentsAnalyticsServiceProtocol.self)
        .asSingleton()
        .with { _ in
          AnalyticsEventService.create(
            environmentProvider: AnalyticsEnvironmentProvider()
          )
        }
    } catch {
      logger.error(message: "Failed to register CheckoutComponentsAnalyticsServiceProtocol: \(error)")
    }

    do {
      try await container.register(CheckoutComponentsAnalyticsInteractorProtocol.self)
        .asSingleton()
        .with { resolver in
          DefaultAnalyticsInteractor(
            eventService: try await resolver.resolve(CheckoutComponentsAnalyticsServiceProtocol.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register CheckoutComponentsAnalyticsInteractorProtocol: \(error)")
    }

    do {
      try await container.register(AccessibilityAnnouncementService.self)
        .asSingleton()
        .with { _ in DefaultAccessibilityAnnouncementService() }
    } catch {
      logger.error(message: "Failed to register AccessibilityAnnouncementService: \(error)")
    }

    do {
      try await container.register(ConfigurationService.self)
        .asSingleton()
        .with { _ in DefaultConfigurationService() }
    } catch {
      logger.error(message: "Failed to register ConfigurationService: \(error)")
    }
  }

  fileprivate func registerValidation() async {
    do {
      try await container.register(RulesFactory.self)
        .asSingleton()
        .with { _ in DefaultRulesFactory() }
    } catch {
      logger.error(message: "Failed to register RulesFactory: \(error)")
    }

    do {
      try await container.register(ValidationService.self)
        .asSingleton()
        .with { resolver in
          let factory = try await resolver.resolve(RulesFactory.self)
          return DefaultValidationService(rulesFactory: factory)
        }
    } catch {
      logger.error(message: "Failed to register ValidationService: \(error)")
    }
  }

  fileprivate func registerDomain() async {
    do {
      try await container.register(GetPaymentMethodsInteractor.self)
        .asTransient()
        .with { resolver in
          GetPaymentMethodsInteractorImpl(
            repository: try await resolver.resolve(HeadlessRepository.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register GetPaymentMethodsInteractor: \(error)")
    }

    do {
      try await container.register(ProcessCardPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessCardPaymentInteractorImpl(
            repository: try await resolver.resolve(HeadlessRepository.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register ProcessCardPaymentInteractor: \(error)")
    }

    do {
      try await container.register(ValidateInputInteractor.self)
        .asTransient()
        .with { resolver in
          ValidateInputInteractorImpl(
            validationService: try await resolver.resolve(ValidationService.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register ValidateInputInteractor: \(error)")
    }

    do {
      try await container.register(CardNetworkDetectionInteractor.self)
        .asTransient()
        .with { resolver in
          CardNetworkDetectionInteractorImpl(
            repository: try await resolver.resolve(HeadlessRepository.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register CardNetworkDetectionInteractor: \(error)")
    }

    do {
      try await container.register(ProcessPayPalPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessPayPalPaymentInteractorImpl(
            repository: try await resolver.resolve(PayPalRepository.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register ProcessPayPalPaymentInteractor: \(error)")
    }

    do {
      try await container.register(ProcessKlarnaPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessKlarnaPaymentInteractorImpl(
            repository: try await resolver.resolve(KlarnaRepository.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register ProcessKlarnaPaymentInteractor: \(error)")
    }

    do {
      try await container.register(ProcessWebRedirectPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessWebRedirectPaymentInteractorImpl(
            repository: try await resolver.resolve(WebRedirectRepository.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register ProcessWebRedirectPaymentInteractor: \(error)")
    }

    do {
      try await container.register(ProcessApplePayPaymentInteractor.self)
        .asTransient()
        .with { _ in
          ProcessApplePayPaymentInteractorImpl(
            tokenizationService: TokenizationService(),
            createPaymentService: CreateResumePaymentService(
              paymentMethodType: PrimerPaymentMethodType.applePay.rawValue)
          )
        }
    } catch {
      logger.error(message: "Failed to register ProcessApplePayPaymentInteractor: \(error)")
    }

    do {
      try await container.register(SubmitVaultedPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          SubmitVaultedPaymentInteractorImpl(
            repository: try await resolver.resolve(HeadlessRepository.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register SubmitVaultedPaymentInteractor: \(error)")
    }

    do {
      try await container.register(ProcessAchPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessAchPaymentInteractorImpl(
            repository: try await resolver.resolve(AchRepository.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register ProcessAchPaymentInteractor: \(error)")
    }
  }

  fileprivate func registerData() async {
    // HeadlessRepository uses transient scope to ensure each checkout session gets a fresh instance.
    // This prevents stale state (e.g., cached card networks, validation handlers) from leaking
    // between checkout sessions when the user dismisses and re-presents the checkout UI.
    // Note: VaultManager is lazily initialized within HeadlessRepositoryImpl for vault payments.
    do {
      try await container.register(HeadlessRepository.self)
        .asTransient()
        .with { _ in HeadlessRepositoryImpl() }
    } catch {
      logger.error(message: "Failed to register HeadlessRepository: \(error)")
    }

    do {
      try await container.register(PaymentMethodMapper.self)
        .asSingleton()
        .with { container in
          let configService = try await container.resolve(ConfigurationService.self)
          return PaymentMethodMapperImpl(configurationService: configService)
        }
    } catch {
      logger.error(message: "Failed to register PaymentMethodMapper: \(error)")
    }

    do {
      try await container.register(PayPalRepository.self)
        .asTransient()
        .with { _ in
          PayPalRepositoryImpl()
        }
    } catch {
      logger.error(message: "Failed to register PayPalRepository: \(error)")
    }

    do {
      try await container.register(KlarnaRepository.self)
        .asTransient()
        .with { _ in
          KlarnaRepositoryImpl()
        }
    } catch {
      logger.error(message: "Failed to register KlarnaRepository: \(error)")
    }

    do {
      try await container.register(AchRepository.self)
        .asTransient()
        .with { _ in
          AchRepositoryImpl()
        }
    } catch {
      logger.error(message: "Failed to register AchRepository: \(error)")
    }

    do {
      try await container.register(WebRedirectRepository.self)
        .asTransient()
        .with { _ in
          WebRedirectRepositoryImpl()
        }
    } catch {
      logger.error(message: "Failed to register WebRedirectRepository: \(error)")
    }

    // Form Redirect (BLIK, MBWay) dependencies
    do {
      try await container.register(FormRedirectRepository.self)
        .asTransient()
        .with { _ in
          FormRedirectRepositoryImpl()
        }
    } catch {
      logger.error(message: "Failed to register FormRedirectRepository: \(error)")
    }

    do {
      try await container.register(ProcessFormRedirectPaymentInteractor.self)
        .asTransient()
        .with { resolver in
          ProcessFormRedirectPaymentInteractorImpl(
            formRedirectRepository: try await resolver.resolve(FormRedirectRepository.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register ProcessFormRedirectPaymentInteractor: \(error)")
    }

    do {
      try await container.register(QRCodeRepository.self)
        .asTransient()
        .with { _ in
          QRCodeRepositoryImpl()
        }
    } catch {
      logger.error(message: "Failed to register QRCodeRepository: \(error)")
    }
  }

  fileprivate func registerLogging() async {
    do {
      try await container.register(LogNetworkClient.self)
        .asSingleton()
        .with { _ in LogNetworkClient() }
    } catch {
      logger.error(message: "Failed to register LogNetworkClient: \(error)")
    }

    do {
      try await container.register(SensitiveDataMasker.self)
        .asSingleton()
        .with { _ in SensitiveDataMasker() }
    } catch {
      logger.error(message: "Failed to register SensitiveDataMasker: \(error)")
    }

    do {
      try await container.register(LogPayloadBuilding.self)
        .asSingleton()
        .with { _ in LogPayloadBuilder() }
    } catch {
      logger.error(message: "Failed to register LogPayloadBuilding: \(error)")
    }

    do {
      try await container.register(LoggingService.self)
        .asSingleton()
        .with { resolver in
          LoggingService(
            networkClient: try await resolver.resolve(LogNetworkClient.self),
            payloadBuilder: try await resolver.resolve(LogPayloadBuilding.self),
            masker: try await resolver.resolve(SensitiveDataMasker.self)
          )
        }
    } catch {
      logger.error(message: "Failed to register LoggingService: \(error)")
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
