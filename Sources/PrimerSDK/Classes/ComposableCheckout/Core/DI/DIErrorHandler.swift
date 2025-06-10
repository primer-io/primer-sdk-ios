//
//  DIErrorHandler.swift
//
//
//  Created by Boris on 25.3.25..
//

import Foundation

/**
 * Centralized error handling for dependency injection operations.
 * Provides recovery strategies and logging for DI-related errors.
 */
@available(iOS 15.0, *)
protocol DIErrorHandler: Sendable {
    /// Handle container errors with potential recovery
    func handleContainerError(_ error: ContainerError) async -> DIErrorRecovery
    
    /// Handle general DI-related errors
    func handleDIError(_ error: Error, context: String) async -> DIErrorRecovery
    
    /// Log DI operations for debugging
    func logDIOperation(_ operation: String, success: Bool, details: String?)
}

@available(iOS 15.0, *)
enum DIErrorRecovery {
    case retry
    case fallback(Any)
    case fail(Error)
    case ignore
}

@available(iOS 15.0, *)
class DefaultDIErrorHandler: DIErrorHandler, LogReporter {
    
    func handleContainerError(_ error: ContainerError) async -> DIErrorRecovery {
        logger.error(message: "🚨 Container error: \(error.localizedDescription)")
        
        switch error {
        case .dependencyNotRegistered(let key):
            logger.error(message: "❌ Dependency not registered: \(key)")
            // Could implement fallback registration here
            return .fail(error)
            
        case .circularDependency(let key, let path):
            logger.error(message: "🔄 Circular dependency detected: \(key) in path: \(path.map { $0.description })")
            return .fail(error)
            
        case .factoryFailed(let key, let underlyingError):
            logger.error(message: "🏭 Factory failed for \(key): \(underlyingError.localizedDescription)")
            return .fail(error)
            
        case .typeCastFailed(let key, let expected, let actual):
            logger.error(message: "🎭 Type cast failed for \(key): expected \(expected), got \(actual)")
            return .fail(error)
            
        case .weakUnsupported(let key):
            logger.error(message: "⚠️ Weak policy unsupported for \(key)")
            return .fail(error)
            
        case .containerUnavailable:
            logger.error(message: "📦 Container unavailable - attempting to create fallback")
            // Could implement fallback container creation
            return .fail(error)
        }
    }
    
    func handleDIError(_ error: Error, context: String) async -> DIErrorRecovery {
        logger.error(message: "🚨 DI Error in \(context): \(error.localizedDescription)")
        
        if let containerError = error as? ContainerError {
            return await handleContainerError(containerError)
        }
        
        // Handle other types of errors
        return .fail(error)
    }
    
    func logDIOperation(_ operation: String, success: Bool, details: String?) {
        let status = success ? "✅" : "❌"
        let message = "\(status) DI Operation: \(operation)"
        
        if success {
            logger.debug(message: message + (details.map { " - \($0)" } ?? ""))
        } else {
            logger.error(message: message + (details.map { " - \($0)" } ?? ""))
        }
    }
}

/**
 * Extension to add error handling capabilities to containers
 */
@available(iOS 15.0, *)
extension ContainerProtocol {
    /// Resolve with error handling and recovery
    func resolveWithErrorHandling<T>(
        _ type: T.Type,
        name: String? = nil,
        errorHandler: DIErrorHandler
    ) async throws -> T {
        do {
            let result = try await resolve(type, name: name)
            await errorHandler.logDIOperation(
                "resolve(\(type))",
                success: true,
                details: name.map { "name: \($0)" }
            )
            return result
        } catch {
            await errorHandler.logDIOperation(
                "resolve(\(type))",
                success: false,
                details: error.localizedDescription
            )
            
            let recovery = await errorHandler.handleDIError(error, context: "resolve(\(type))")
            
            switch recovery {
            case .retry:
                // Attempt resolution again
                return try await resolve(type, name: name)
            case .fallback(let fallbackValue):
                guard let typedFallback = fallbackValue as? T else {
                    throw ContainerError.typeCastFailed(
                        TypeKey(type, name: name),
                        expected: T.self,
                        actual: Swift.type(of: fallbackValue)
                    )
                }
                return typedFallback
            case .fail(let recoveryError):
                throw recoveryError
            case .ignore:
                throw error // Re-throw original error
            }
        }
    }
}