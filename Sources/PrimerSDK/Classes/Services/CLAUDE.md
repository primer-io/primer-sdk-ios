# CLAUDE.md - Services

This directory contains the service layer infrastructure that provides networking, data processing, and external service integration capabilities for the Primer iOS SDK.

## Overview

The Services layer acts as the bridge between the domain models and external systems (APIs, third-party services, etc.). It provides clean abstractions for networking, data parsing, and service integration while maintaining separation of concerns.

## Architecture

### Service Categories

#### Network Services (`Network/`)
Core networking infrastructure for API communication:

**API Client Core**:
- `PrimerAPIClient.swift`: Main API client implementation
- `PrimerAPIClientProtocol.swift`: API client interface for dependency injection
- `NetworkService.swift`: Low-level networking utilities
- `Endpoint.swift`: API endpoint definitions and URL construction

**Specialized API Protocols** (`Protocols/`):
Protocol-based API segmentation for better testability:
- `PrimerAPIClientAnalyticsProtocol.swift`: Analytics event submission
- `PrimerAPIClientBINDataProtocol.swift`: Bank Identification Number lookup
- `PrimerAPIClientCreateResumePaymentProtocol.swift`: Payment processing
- `PrimerAPIClientVaultProtocol.swift`: Stored payment method operations
- `PrimerAPIClientPayPalProtocol.swift`: PayPal-specific integrations
- `PrimerAPIClientBanksProtocol.swift`: Banking service integrations
- `PrimerAPIClientAchProtocol.swift`: ACH transfer operations
- `PrimerAPIClientXenditProtocol.swift`: Xendit payment method integrations

**Network Infrastructure**:
- `RetryConfiguration.swift`: Intelligent retry logic with exponential backoff
- `SuccessResponse.swift`: Standardized success response handling
- `WebAuthenticationService.swift`: OAuth and web-based authentication flows

#### Data Processing (`Parser/`)
Data transformation and processing services:
- `Parser.swift`: Generic data parsing utilities and JSON processing

## Network Service Architecture

### API Client Pattern
The API client uses a protocol-based architecture for modularity and testability:

```swift
// Protocol definition
protocol PrimerAPIClientAnalyticsProtocol {
    func submitAnalyticsEvents(_ events: [AnalyticsEvent]) async throws
}

// Implementation
extension PrimerAPIClient: PrimerAPIClientAnalyticsProtocol {
    func submitAnalyticsEvents(_ events: [AnalyticsEvent]) async throws {
        // Implementation
    }
}
```

### Dependency Injection Integration
Services are designed to work with both legacy and modern DI systems:

```swift
// Legacy DI registration
DependencyContainer.register(PrimerAPIClientProtocol.self) { resolver in
    PrimerAPIClient(networkService: resolver.resolve(NetworkService.self))
}

// Modern DI registration (CheckoutComponents)
_ = try await container.register(PrimerAPIClientProtocol.self)
    .asSingleton()
    .with { resolver in
        PrimerAPIClient(networkService: try await resolver.resolve(NetworkService.self))
    }
```

## Service Implementations

### Core API Operations

#### Payment Processing Services
**Create/Resume Payment Flow**:
- Payment creation with merchant configuration
- Payment resumption for 3DS and other redirects
- Payment status polling and updates
- Error handling and retry logic

#### Vault Management Services
**Stored Payment Methods**:
- Payment method storage and retrieval
- Customer vault management
- Token lifecycle management
- Security validation for stored methods

#### Analytics Services
**Event Tracking and Reporting**:
- Real-time event collection
- Batch event submission
- Performance metrics tracking
- Error reporting and debugging

### Specialized Payment Services

#### Bank Data Services (`BINDataProtocol`)
**Bank Identification Number Operations**:
- Card network detection from card number
- Bank metadata retrieval
- Card validation rules fetching
- Real-time BIN lookup with caching

#### PayPal Integration (`PayPalProtocol`)
**PayPal Service Operations**:
- OAuth token management
- PayPal order creation and capture
- Billing agreement setup
- Error handling for PayPal-specific scenarios

#### ACH Services (`AchProtocol`)
**Automated Clearing House Operations**:
- Bank account validation
- ACH transaction initiation
- Mandate management
- Status tracking and updates

### Network Infrastructure

#### Retry Configuration
Intelligent retry mechanism for network resilience:

```swift
struct RetryConfiguration {
    let maxAttempts: Int = 3
    let baseDelay: TimeInterval = 1.0
    let maxDelay: TimeInterval = 30.0
    let backoffMultiplier: Double = 2.0
    
    // Exponential backoff with jitter
    func delayForAttempt(_ attempt: Int) -> TimeInterval {
        let delay = min(baseDelay * pow(backoffMultiplier, Double(attempt)), maxDelay)
        let jitter = delay * Double.random(in: 0.8...1.2)
        return jitter
    }
}
```

#### Error Handling Strategy
Layered error handling with recovery mechanisms:

1. **Network Errors**: Connection issues, timeouts, DNS failures
2. **HTTP Errors**: Status code based error handling
3. **API Errors**: Business logic errors from server
4. **Parsing Errors**: Data format and structure issues

```swift
enum NetworkError: Error {
    case connectionFailed
    case timeout
    case unauthorized
    case serverError(Int)
    case parsingError
    case unknown(Error)
}
```

### Authentication Services

#### Web Authentication Service
OAuth and web-based authentication handling:

**Features**:
- In-app browser integration
- OAuth 2.0 flow management
- PKCE (Proof Key for Code Exchange) support
- Deep link handling and redirect management
- SSL certificate validation

**Usage Pattern**:
```swift
let authService = WebAuthenticationService()
let result = try await authService.authenticate(
    url: oauthURL,
    callbackScheme: "primer-app"
)
```

## Integration Patterns

### Service Layer Usage

#### In Drop-in/Headless (Legacy)
```swift
class PaymentService {
    private let apiClient: PrimerAPIClientProtocol
    
    init() {
        self.apiClient = DependencyContainer.resolve()
    }
    
    func processPayment(_ data: PaymentData) async throws -> PaymentResult {
        return try await apiClient.createPayment(data)
    }
}
```

#### In CheckoutComponents (Modern)
```swift
@MainActor
class PaymentService {
    private let apiClient: PrimerAPIClientProtocol
    
    init(apiClient: PrimerAPIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func processPayment(_ data: PaymentData) async throws -> PaymentResult {
        return try await apiClient.createPayment(data)
    }
}
```

### Error Propagation
Services use Result types and async throws for error handling:

```swift
protocol PaymentServiceProtocol {
    func processPayment(_ data: PaymentData) async throws -> PaymentResult
}

// Usage
do {
    let result = try await paymentService.processPayment(paymentData)
    // Handle success
} catch NetworkError.unauthorized {
    // Handle authentication error
} catch NetworkError.serverError(let code) {
    // Handle server error
} catch {
    // Handle general error
}
```

## Performance Optimizations

### Network Performance
1. **Connection Pooling**: Reuse HTTP connections
2. **Request Batching**: Combine multiple requests where possible
3. **Compression**: GZIP compression for large payloads
4. **Caching**: Intelligent caching for configuration and metadata

### Data Processing
1. **Streaming**: Large data sets processed as streams
2. **Background Processing**: Heavy parsing on background queues
3. **Memory Management**: Efficient memory usage for large responses
4. **Lazy Loading**: On-demand data loading

### API Efficiency
1. **GraphQL Support**: Flexible data fetching (where supported)
2. **Field Selection**: Request only needed fields
3. **Pagination**: Handle large data sets efficiently
4. **Delta Updates**: Incremental data synchronization

## Security Considerations

### Network Security
1. **Certificate Pinning**: Validate SSL certificates
2. **Request Signing**: Sign sensitive requests
3. **Token Management**: Secure token storage and refresh
4. **Data Encryption**: Encrypt sensitive data in transit

### API Security
1. **Authentication**: OAuth 2.0 and API key management
2. **Authorization**: Role-based access control
3. **Rate Limiting**: Respect API rate limits
4. **Audit Logging**: Track security-relevant events

## Testing Strategy

### Service Testing
1. **Unit Tests**: Test individual service methods
2. **Integration Tests**: Test service interactions
3. **Network Mocking**: Mock API responses for testing
4. **Error Scenario Testing**: Test all error conditions

### Network Testing
1. **Connectivity Testing**: Various network conditions
2. **Performance Testing**: Latency and throughput
3. **Security Testing**: Certificate validation
4. **Reliability Testing**: Connection failures and recovery

## Monitoring and Debugging

### Logging
Services include comprehensive logging:

```swift
class PrimerAPIClient: LogReporter {
    func makeRequest<T>(_ request: APIRequest) async throws -> T {
        logger.info(message: "Making request to \(request.endpoint)")
        
        do {
            let response = try await networkService.execute(request)
            logger.debug(message: "Request successful: \(response.statusCode)")
            return response.data
        } catch {
            logger.error(message: "Request failed: \(error)")
            throw error
        }
    }
}
```

### Metrics Collection
Services collect performance and reliability metrics:
- Request latency tracking
- Error rate monitoring
- Success rate measurement
- Retry attempt tracking

### Debugging Tools
1. **Network Debugging**: Request/response logging
2. **Performance Profiling**: Service performance analysis
3. **Error Tracking**: Comprehensive error reporting
4. **Health Checks**: Service availability monitoring

This service architecture provides a robust, scalable foundation for network operations while maintaining clean abstractions and excellent testability across all SDK integration approaches.