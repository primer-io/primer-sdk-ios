# CheckoutComponents Consolidation Implementation Plan

## Overview
Consolidate 4 buttons (Drop-in, Headless, CheckoutComponents UIKit, CheckoutComponents SwiftUI) into 3 buttons by combining the 2 CheckoutComponents buttons into one unified flow with better navigation and examples showcase.

## Current State Analysis
- **Current buttons**: Drop-in, Headless, CheckoutComponents UIKit, CheckoutComponents SwiftUI
- **Target buttons**: Drop-in, Headless, CheckoutComponents (unified)
- **Current showcase**: 18 examples in `/Debug App/Sources/View Controllers/CheckoutComponentsShowcase/`
- **Current session creation**: Happens when buttons are tapped in main settings screen

## Target Architecture

### Navigation Flow
```
Main Settings Screen (3 buttons)
├── Drop-in Button → (unchanged)
├── Headless Button → (unchanged)
└── CheckoutComponents Button → CheckoutComponentsMenuViewController
    ├── UIKit Integration Button → (current checkoutComponentsUIKitButton behavior)
    └── SwiftUI Examples Button → CheckoutComponentsExamplesView (SwiftUI)
        ├── Layout Configurations → LayoutExamplesView
        │   ├── Compact Layout → Modal PrimerCheckout (card-only)
        │   ├── Expanded Layout → Modal PrimerCheckout (card + Apple Pay)
        │   ├── Inline Layout → Modal PrimerCheckout (full methods)
        │   └── Grid Layout → Modal PrimerCheckout (custom config)
        ├── Styling Variations → StylingExamplesView
        │   ├── Corporate Theme → Modal PrimerCheckout
        │   ├── Modern Theme → Modal PrimerCheckout
        │   ├── Colorful Theme → Modal PrimerCheckout
        │   └── Dark Theme → Modal PrimerCheckout
        ├── Interactive Features → InteractiveExamplesView
        │   ├── Live State Demo → Modal PrimerCheckout
        │   ├── Validation Showcase → Modal PrimerCheckout
        │   └── Co-badged Cards → Modal PrimerCheckout
        └── Advanced Customization → AdvancedExamplesView
            ├── Modifier Chains → Modal PrimerCheckout
            ├── Custom Screen Layout → Modal PrimerCheckout
            └── Animation Playground → Modal PrimerCheckout
```

## Implementation Tasks

### Phase 1: Main Settings Screen Updates

#### Task 1.1: Update MerchantSessionAndSettingsViewController.swift
- **Remove**: `checkoutComponentsUIKitButton` and `checkoutComponentsSwiftUIButton` properties
- **Add**: Single `checkoutComponentsButton` property
- **Update**: `setupCheckoutComponentsButtons()` method to create single button
- **Update**: All render mode cases to show/hide single button
- **Add**: `@objc func checkoutComponentsButtonTapped()` action method

#### Task 1.2: Button Configuration
```swift
// Replace existing CC buttons with single button
checkoutComponentsButton = UIButton(type: .system)
checkoutComponentsButton.setTitle("CheckoutComponents", for: .normal)
checkoutComponentsButton.backgroundColor = UIColor.systemPurple
checkoutComponentsButton.addTarget(self, action: #selector(checkoutComponentsButtonTapped), for: .touchUpInside)
```

### Phase 2: Intermediate Menu Screen

#### Task 2.1: Create CheckoutComponentsMenuViewController.swift
```swift
class CheckoutComponentsMenuViewController: UIViewController {
    // Properties for settings and client session data
    var settings: PrimerSettings!
    var clientSession: ClientSessionRequestBody!
    var apiVersion: PrimerApiVersion!
    
    // UI Elements (programmatic)
    private var uikitIntegrationButton: UIButton!
    private var swiftUIExamplesButton: UIButton!
    private var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "CheckoutComponents"
        
        // Create buttons programmatically
        uikitIntegrationButton = createButton(
            title: "UIKit Integration",
            backgroundColor: .systemBlue,
            action: #selector(uikitIntegrationTapped)
        )
        
        swiftUIExamplesButton = createButton(
            title: "SwiftUI Examples",
            backgroundColor: .systemPurple,
            action: #selector(swiftUIExamplesTapped)
        )
        
        // Create stack view
        stackView = UIStackView(arrangedSubviews: [uikitIntegrationButton, swiftUIExamplesButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
    }
    
    private func createButton(title: String, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = backgroundColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            uikitIntegrationButton.heightAnchor.constraint(equalToConstant: 50),
            swiftUIExamplesButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func uikitIntegrationTapped() {
        // Use existing checkoutComponentsUIKitButton logic
    }
    
    @objc private func swiftUIExamplesTapped() {
        // Present CheckoutComponentsExamplesView
    }
}
```

#### Task 2.2: No Storyboard Changes Required
- All UI created programmatically in code
- No storyboard scenes or segues needed

#### Task 2.3: Navigation Logic
- **UIKit Integration**: Use existing `checkoutComponentsUIKitButton` logic
- **SwiftUI Examples**: Present `CheckoutComponentsExamplesView` as SwiftUI modal

### Phase 3: SwiftUI Examples Architecture

#### Task 3.1: Create CheckoutComponentsExamplesView.swift
```swift
@available(iOS 15.0, *)
struct CheckoutComponentsExamplesView: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Layout Configurations", destination: LayoutExamplesView(...))
                NavigationLink("Styling Variations", destination: StylingExamplesView(...))
                NavigationLink("Interactive Features", destination: InteractiveExamplesView(...))
                NavigationLink("Advanced Customization", destination: AdvancedExamplesView(...))
            }
            .navigationTitle("CheckoutComponents Examples")
        }
    }
}
```

#### Task 3.2: Create Category Views
Create 4 separate SwiftUI view files:
- `LayoutExamplesView.swift`
- `StylingExamplesView.swift` 
- `InteractiveExamplesView.swift`
- `AdvancedExamplesView.swift`

Each following this pattern:
```swift
@available(iOS 15.0, *)
struct LayoutExamplesView: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    @State private var showingCheckout = false
    @State private var selectedExample: ExampleConfig?
    
    var body: some View {
        List {
            ForEach(layoutExamples) { example in
                ExampleRow(
                    example: example,
                    onTap: { 
                        selectedExample = example
                        showingCheckout = true 
                    }
                )
            }
        }
        .sheet(isPresented: $showingCheckout) {
            if let example = selectedExample {
                CheckoutExampleView(example: example, settings: settings)
            }
        }
    }
}
```

### Phase 4: Example Configuration System

#### Task 4.1: Create ExampleConfig Model
```swift
struct ExampleConfig: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let sessionType: SessionType
    let paymentMethods: [String]
    let customization: CheckoutCustomization?
    
    enum SessionType {
        case cardOnly
        case cardAndApplePay
        case fullMethods
        case custom(ClientSessionRequestBody.PaymentMethod)
    }
}
```

#### Task 4.2: Define All 18 Example Configurations
```swift
// In LayoutExamplesView.swift
private let layoutExamples: [ExampleConfig] = [
    ExampleConfig(
        name: "Compact Layout",
        description: "Horizontal fields with tight spacing",
        sessionType: .cardOnly,
        paymentMethods: ["PAYMENT_CARD"],
        customization: .compact
    ),
    ExampleConfig(
        name: "Expanded Layout", 
        description: "Vertical fields with generous spacing",
        sessionType: .cardAndApplePay,
        paymentMethods: ["PAYMENT_CARD", "APPLE_PAY"],
        customization: .expanded
    ),
    // ... continue for all examples
]
```

#### Task 4.3: Session Configuration Mapping
```swift
extension ExampleConfig {
    func createSession() -> ClientSessionRequestBody {
        switch sessionType {
        case .cardOnly:
            return MerchantMockDataManager.getClientSession(sessionType: .cardOnly)
        case .cardAndApplePay:
            return MerchantMockDataManager.getClientSession(sessionType: .cardAndApplePay)
        case .fullMethods:
            return MerchantMockDataManager.getClientSession(sessionType: .generic)
        case .custom(let paymentMethod):
            var session = MerchantMockDataManager.getClientSession(sessionType: .generic)
            session.paymentMethod = paymentMethod
            return session
        }
    }
}
```

### Phase 5: Pure SwiftUI PrimerCheckout Integration

#### Task 5.1: Create CheckoutExampleView.swift
```swift
@available(iOS 15.0, *)
struct CheckoutExampleView: View {
    let example: ExampleConfig
    let settings: PrimerSettings
    
    @Environment(\.dismiss) private var dismiss
    @State private var clientToken: String?
    @State private var isLoading = true
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Creating session...")
                } else if let error = error {
                    ErrorView(error: error)
                } else if let clientToken = clientToken {
                    PrimerCheckout(
                        clientToken: clientToken,
                        settings: settings
                        // Use default DI container and navigator
                    )
                    .onReceive(checkoutCompleted) { _ in
                        dismiss()
                    }
                }
            }
            .navigationTitle(example.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            await createSession()
        }
    }
    
    private func createSession() async {
        // Create session based on example configuration
        let session = example.createSession()
        
        // Request client token
        // Handle success/failure
        // Set clientToken or error
    }
}
```

#### Task 5.2: Session Configuration Info Display
```swift
struct ExampleRow: View {
    let example: ExampleConfig
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(example.name)
                    .font(.headline)
                
                Text(example.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Payment Methods:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(example.paymentMethods.joined(separator: ", "))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
```

### Phase 6: MerchantMockDataManager Updates

#### Task 6.1: Add New Session Types
```swift
// In MerchantHelpers.swift
enum SessionType {
    case generic
    case klarnaWithEMD
    case cardOnly
    case cardAndApplePay // New
    case applePay // New
    case custom(ClientSessionRequestBody.PaymentMethod) // New
}
```

#### Task 6.2: Create Session Configurations
```swift
static var cardAndApplePayMethod = ClientSessionRequestBody.PaymentMethod(
    vaultOnSuccess: false,
    options: ClientSessionRequestBody.PaymentMethod.PaymentMethodOptionGroup(
        PAYMENT_CARD: cardOption,
        APPLE_PAY: applePayOption
    ),
    descriptor: "Card and Apple Pay session",
    paymentType: nil
)
```

## Deferred Tasks & Technical Notes

### Future Enhancement: DI Container Simplification
**Issue**: Current CheckoutComponents requires complex DI setup that merchants shouldn't handle.
**Solution**: Consider adding DI configuration to `PrimerSettings.swift` to enable simpler public API:
```swift
// Future API possibility
let settings = PrimerSettings(
    paymentHandling: .auto,
    checkoutComponentsOptions: CheckoutComponentsOptions(
        navigationStyle: .default,
        customization: .modern
    )
)
```
**Priority**: Separate ticket - not blocking current implementation.

### Future Enhancement: Custom Navigation
**Current**: Using default navigator for all examples
**Future**: Allow easy navigation customization from outside CheckoutComponents
**API Idea**: Navigation configuration in settings or as separate parameter

## File Structure After Implementation

```
Debug App/Sources/View Controllers/
├── MerchantSessionAndSettingsViewController.swift (updated)
├── CheckoutComponentsMenuViewController.swift (new)
├── CheckoutComponents/
│   ├── CheckoutComponentsExamplesView.swift (new)
│   ├── LayoutExamplesView.swift (new)
│   ├── StylingExamplesView.swift (new)
│   ├── InteractiveExamplesView.swift (new)
│   ├── AdvancedExamplesView.swift (new)
│   ├── CheckoutExampleView.swift (new)
│   └── ExampleConfig.swift (new)
└── CheckoutComponentsShowcase/ (reference for configurations)
```

## Implementation Order

1. **Phase 1**: Update main settings screen (single button)
2. **Phase 2**: Create intermediate menu screen  
3. **Phase 6**: Update MerchantMockDataManager with new session types
4. **Phase 4**: Create example configuration system
5. **Phase 3**: Create SwiftUI examples navigation
6. **Phase 5**: Implement pure SwiftUI PrimerCheckout integration

## Success Criteria

- ✅ 4 buttons consolidated to 3 buttons
- ✅ Clear separation: UIKit integration vs SwiftUI examples
- ✅ All 18 examples accessible with individual configurations
- ✅ Session configuration visible to users
- ✅ Pure SwiftUI flow (no PrimerSwiftUIBridgeViewController)
- ✅ Delayed session creation (only when example selected)
- ✅ Clean navigation: separate files, modal presentation
- ✅ Auto-dismiss on completion to main screen

## Risk Mitigation

- **Risk**: CheckoutComponents DI complexity
  **Mitigation**: Use default containers, defer advanced DI to future ticket
- **Risk**: SwiftUI navigation complexity  
  **Mitigation**: Keep navigation simple with standard NavigationView/NavigationLink
- **Risk**: Session configuration complexity
  **Mitigation**: Start with predefined configurations, extend as needed

This plan maintains the current functionality while providing a much cleaner and more discoverable way for users to explore CheckoutComponents capabilities.
