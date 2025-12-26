# Code Style and Conventions

## Formatting Tool
The project uses **SwiftFormat** for automatic code formatting.

### SwiftFormat Configuration
Configuration file: `BuildTools/.swiftformat`

**Active Rules:**
```
--rules isEmpty, preferCountWhere, redundantExtensionACL, modifierOrder, 
consecutiveBlankLines, blankLineAfterImports, andOperator, elseOnSameLine, 
fileHeader, hoistPatternLet, leadingDelimiters, modifiersOnSameLine, 
preferKeyPath, redundantInternal
```

### Running SwiftFormat
- **Manual formatting**: `swiftformat <file_or_directory> --config BuildTools/.swiftformat`
- **Automatic**: Pre-commit hook applies formatting to staged Swift files

## File Headers
All Swift files should include the standard file header:
```swift
//
//  FileName.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.
```

## Code Organization

### Imports
- UIKit and Foundation imports should be at the top
- Third-party imports follow system imports
- Blank line after imports (enforced by SwiftFormat)

### Class/Struct Structure
Common pattern observed in the codebase:
```swift
public final class ClassName {
    
    // MARK: - PROPERTIES
    
    // Properties here
    
    // MARK: - INITIALIZATION
    
    // Init methods here
    
    // MARK: - PUBLIC METHODS
    
    // Public interface
    
    // MARK: - PRIVATE METHODS
    
    // Private implementation
}
```

### Access Control
- Use explicit access control modifiers where appropriate
- `public` for SDK public API
- `internal` is default (can be omitted per SwiftFormat redundantInternal rule)
- `private` for implementation details

### Naming Conventions
- **Classes/Structs**: PascalCase (e.g., `PrimerSDK`, `PaymentMethodTokenizationViewModel`)
- **Methods/Properties**: camelCase
- **Constants**: camelCase for instance properties, can use SCREAMING_SNAKE_CASE for static/global constants
- **Protocols**: Descriptive names often ending in `Delegate`, `Protocol`, `Providing`, etc.

### Extensions
- Use extensions to organize code by functionality
- Extension file naming: `OriginalType+Extension.swift` or `OriginalType+Functionality.swift`
  - Examples: `UIColorExtension.swift`, `PrimerTheme+Colors.swift`

## SwiftLint
The codebase uses SwiftLint directives inline:
```swift
// swiftlint:disable rule_name
// Code here
// swiftlint:enable rule_name
```

## Testing Conventions
- Test files located in `Tests/` directory
- Test target naming: `Tests`, `DebugAppTests`
- Test plans: `.xctestplan` files for organizing test suites

## Documentation
- Use Swift documentation comments for public APIs
- Include examples in documentation where helpful
- Reference the main documentation at https://primer.io/docs
