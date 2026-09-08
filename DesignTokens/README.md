# Design Tokens for iOS

This repository uses [Style Dictionary](https://amzn.github.io/style-dictionary/) to generate Swift classes representing design tokens for your iOS SDK. The tokens are provided in JSON files (one for light mode and one for dark mode) by the design team. The generated Swift classes are flat, SwiftUI‑compatible, and conform to `Decodable` so that they can be parsed dynamically at runtime if a new JSON is fetched (for dynamic theming).

---

## Installation & Setup

1. **Clone the repository and navigate to the design tokens folder:**

   ```bash
   git clone <repository-url>
   cd /path/to/your/DesignTokens
   ```

2. **Install dependencies:**

   Make sure you have Node.js (v18 or later) installed. Then run:

   ```bash
   npm install
   ```

   This installs Style Dictionary as a dev dependency.

3. **Review Your Tokens:**

   Place your token JSON files in the tokens/ folder:
   - `tokens/base.json` – Light theme tokens.
   - `tokens/dark.json` – Dark theme tokens.

4. **Understanding the Configuration Files:**

   One configuration file is provided:

   - `config-light.js`:
     - This file registers a custom Swift format to generate a flat SwiftUI‑compatible class (named `DesignTokensLight`).
     - It reads tokens from `tokens/base.json` and uses a custom transform group (`primer-ios-swiftui`) that converts names to camel case, formats colors using a custom `color/ColorSwiftUI` transform, and outputs literal values for content and assets.
     - Developer Note: We omit the default 'size/swift/remToCGFloat' transform so that dimension tokens (e.g. spaces and sizes) are computed without extra arithmetic wrappers. In this file, when dimension tokens are encountered, we remove any unwanted wrappers and evaluate the arithmetic to output a raw numeric value.


5. **Build the Tokens:**

   To generate the Swift files, run:

   ```bash
   npm run build
   ```

   This runs:
   - `npm run build-light` – Generates `DesignTokensLight.swift` in the build path.

   The output files are placed in your iOS project under `../Sources/PrimerSDK/Classes/Components/Design/`.

## Customization & How It Works

### Custom Swift Format

In `config-light.js`, a custom format is registered using:

```js
StyleDictionary.registerFormat({
  name: 'primer/ios/swift',
  format: function({ dictionary }) {
    // The generated file begins with Swift lint directives and imports SwiftUI.
    // A class is defined (DesignTokens) that conforms to Decodable.
    // For each token, we:
    //   - Determine the Swift type based on the token type:
    //       • Color for color tokens.
    //       • CGFloat for dimension tokens.
    //       • String for string tokens.
    //   - For dimension tokens, we strip any unwanted wrappers and evaluate the arithmetic expression.
    //   - Each token becomes a public optional property with a default value computed from the JSON.
    //   - CodingKeys are automatically generated to match the property names.
    //   - A custom init(from decoder:) is implemented to decode colors from an array of CGFloat values.
    return `...`;
  }
});
```

### Custom Transform Group

A custom transform group is also registered:

```js
StyleDictionary.registerTransformGroup({
  name: 'primer-ios-swiftui',
  transforms: [
    'attribute/cti',           // Adds category, type, item attributes.
    'name/camel',              // Converts token names to camelCase.
    'color/ColorSwiftUI',      // Custom transform to output SwiftUI Color initializer strings.
    'content/swift/literal',   // Formats literal content for Swift.
    'asset/swift/literal'      // Formats asset tokens for Swift.
    // We intentionally omit 'size/swift/remToCGFloat' to avoid unwanted multiplication wrappers.
  ]
});
```

### Why We Evaluate Dimensions Manually

You may notice that previously, tokens like space or size were being generated as expressions like:

```swift
CGFloat(64.00) * 0.50
```

This caused runtime errors because CGFloat isn't defined in the Node.js environment when evaluating these arithmetic expressions. Our custom code now strips those wrappers and uses eval() on the raw arithmetic (e.g. "64.00 * 0.50") so that the output is a plain number (e.g. 32) that can be directly assigned as a CGFloat value in Swift.

## How to Update Tokens

1. **Update the JSON Files:**
   - When the design team provides new tokens or updates the existing ones, replace the contents of `tokens/base.json` and/or `tokens/dark.json`.

2. **Rebuild the Tokens:**
   - Run the build script again:

   ```bash
   npm run build
   ```

   This regenerates the Swift file with the latest values.

3. **Integrate with Your iOS Project:**
   - The generated `DesignTokens.swift` carries the compiled-in light defaults. Dark mode is resolved at runtime by `DesignTokensManager`, which merges `dark.json` over `base.json` and decodes into the same type — there is no separate dark class.

## Additional Notes

### Dynamic Theming:
The generated class conforms to Decodable so that at runtime you can parse a JSON payload (if you choose to fetch updated tokens from an API) into these models. This allows dynamic theming of the SDK based on user-selected branding.

### Extending the Approach:
The approach shown here can be extended to generate other assets or to support additional platforms. Developers can register their own custom formats and transform groups following the Style Dictionary reference.

### Troubleshooting:
If you encounter issues with arithmetic expressions or token transformations, check the console for errors during the build. The custom code in the config files logs evaluation errors to help pinpoint problematic token values.

With this setup and documentation, your iOS token generation process should be clear for any developer joining the project. Happy theming!
