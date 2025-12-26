# Codebase Structure

## Top-Level Directory Organization

```
primer-sdk-ios/
├── Sources/              # Main SDK source code
├── Debug App/            # Demo application for testing
├── Tests/                # Test suites
├── BuildTools/           # Build configuration and tools
├── Scripts/              # Utility scripts
├── fastlane/             # Fastlane automation
├── .github/              # GitHub workflows and templates
├── Package.swift         # Main SPM package definition
├── Package.*.swift       # Variant package definitions (Klarna, Stripe, etc.)
├── PrimerSDK.podspec     # CocoaPods specification
├── Makefile              # Build automation
└── README.md             # Project documentation
```

## Source Code Structure (`Sources/PrimerSDK/`)

### Main Components

```
Sources/PrimerSDK/
├── Classes/              # All Swift source files
│   ├── Core/            # Core SDK functionality
│   ├── PCI/             # PCI-compliant payment processing
│   ├── Data Models/     # Data structures and models
│   ├── Extensions & Utilities/  # Helper extensions
│   ├── Services/        # Network and API services
│   ├── User Interface/  # UI components
│   ├── Error Handler/   # Error handling
│   └── Modules/         # Feature modules
└── Resources/           # Assets, localization files
```

### Core (`Sources/PrimerSDK/Classes/Core/`)

Central SDK functionality:
- **Primer/**: Main SDK interface (`Primer.swift`, `PrimerDelegate.swift`)
- **PrimerHeadlessUniversalCheckout/**: Headless checkout implementation
  - Managers/: Payment method managers
  - Composable/: Composable payment components (Klarna, ACH, NolPay, etc.)
  - Models/: Headless checkout data models
- **3DS/**: 3D Secure 2.0 integration
- **Analytics/**: Event tracking and analytics
- **Logging/**: Logging infrastructure
- **Payment Services/**: Payment processing services
- **Cache/**: Configuration caching
- **Keychain/**: Secure storage
- **Connectivity/**: Network connectivity monitoring
- **Constants/**: App-wide constants (Strings, Colors, Dimensions)

### PCI (`Sources/PrimerSDK/Classes/PCI/`)

PCI-compliant card handling:
- **Tokenization View Models/**: Form tokenization logic
  - FormsTokenizationViewModel/: Card form handling
  - Fields/: Individual form fields (CVV, Card Number, Expiry, etc.)
- **Checkout Components/**: Card data components
- **Services/**: PCI-specific network services
- **User Interface/**: PCI-compliant UI components
  - Text Fields/: Secure text input fields

### Data Models (`Sources/PrimerSDK/Classes/Data Models/`)

- **API/**: API request/response models
- **Theme/**: Theming and styling
  - Public/: Public theme API
  - Internal/: Internal theme implementation
- **Currency/**: Currency handling
- **PCI/**: PCI-related data models
- Various payment method models (ApplePay, PayPal, Klarna, ACH, etc.)

### Extensions & Utilities (`Sources/PrimerSDK/Classes/Extensions & Utilities/`)

Helpers and extensions for:
- UIKit extensions (UIColor, UIImage, UIDevice, UIViewController, etc.)
- Foundation extensions (String, Data, Date, Dictionary, Array)
- Custom utilities (ApplePayUtils, DeeplinkUtils, ImageFileProcessor, Mask, etc.)
- Custom UI components (PrimerButton, PrimerImageView, PrimerStackView)

### Services (`Sources/PrimerSDK/Classes/Services/`)

- **Network/**: Networking layer
  - PrimerAPIClient.swift: Main API client
  - Protocols/: API protocol definitions (Analytics, Vault, Payment, etc.)
  - Endpoint.swift: API endpoint definitions
- **Parser/**: JSON parsing utilities

### User Interface (`Sources/PrimerSDK/Classes/User Interface/`)

UI components and view controllers:
- **Root/**: Main view controllers
  - PrimerRootViewController: Base container
  - PrimerUniversalCheckoutViewController: Main checkout UI
  - CVVRecapture/: CVV recapture flow
- **TokenizationViewModels/**: Payment method tokenization logic
- **TokenizationViewControllers/**: Payment method view controllers
- **Components/**: Reusable UI components
- **Text Fields/**: Custom text input fields
- **Vault/**: Vault management UI
- **Banks/**: Bank selection UI
- **Countries/**: Country selection UI
- Payment method specific UIs (Klarna, ACH, OAuth, QR Code, etc.)

## Test Structure (`Tests/`)

```
Tests/
├── Primer/              # SDK core tests
├── 3DS/                 # 3D Secure tests
└── Utilities/           # Test utilities and helpers
```

## Debug App Structure (`Debug App/`)

```
Debug App/
├── Sources/             # Debug app source code
│   ├── Utilities/      # Test utilities
│   └── Model/          # Test settings and configuration
├── Tests/               # Debug app tests
├── Podfile              # CocoaPods dependencies
└── Primer.io Debug App.xcodeproj  # Xcode project
```

## Build Tools (`BuildTools/`)

- `.swiftformat`: SwiftFormat configuration
- `git-format-staged.sh`: Git hook script for formatting staged files

## Multiple Package Configurations

The repository maintains several Package.swift variants:
- `Package.swift`: Main package (default with 3DS)
- `Package.Development.swift`: Development configuration
- `Package.Klarna.swift`: Klarna integration
- `Package.Stripe.swift`: Stripe integration
- `Package.NolPay.swift`: NolPay integration
- `Package.3DS.swift`: 3DS specific
- `Package.vanilla.swift`: Minimal/vanilla configuration

## Key Files

- **Makefile**: Build automation (e.g., `make hook` for git hooks)
- **Dangerfile.swift**: PR automation rules
- **Gemfile**: Ruby dependencies (Fastlane, CocoaPods)
- **phrase_config.yml**: Localization configuration
- **sonar-project.properties**: SonarQube configuration
- **.gitlab-ci.yml**: GitLab CI pipeline (for releases)
