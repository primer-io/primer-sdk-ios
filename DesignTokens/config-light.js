import StyleDictionary from 'style-dictionary';

// Register a custom Swift format that creates a flat SwiftUI-compatible class.
// All tokens become optional properties with default values computed from the JSON.
// The class conforms to Decodable so that later you can parse a JSON version of these tokens.
StyleDictionary.registerFormat({
  name: 'primer/ios/swift',
  format: function({ dictionary }) {
    return `// swiftlint:disable all
import SwiftUI

// This class is generated automatically by Style Dictionary.
// It represents the design tokens for the Light theme.
internal class DesignTokensLight: Decodable {
    ${dictionary.allTokens.map(function(token) {
      let type;
      let value;
      
      // Determine the Swift type and compute the token value
      if (token.type === 'color') {
        // For color tokens, we assume the token value is already a valid SwiftUI Color initializer string.
        type = 'Color';
        value = token.value;
      } else if (token.type === 'dimension') {
        // For dimension tokens, we want to output a computed CGFloat value.
        // Our tokens are provided as a string in the form "CGFloat(64.00) * 0.50" etc.
        // We need to strip the "CGFloat(" prefix and the first ")" so that the arithmetic can be evaluated.
        type = 'CGFloat';
        if (typeof token.value === 'string') {
          let raw = token.value.replace(/CGFloat\$begin:math:text$/g, '').replace(/\\$end:math:text$/g, '');
          // Remove the "CGFloat(" prefix and the first ")" from the token value.
          try {
            // Evaluate the arithmetic expression (e.g. "64.00 * 0.50") to get a number.
            value = Number(eval(raw));
          } catch (error) {
            console.error("Error evaluating dimension token:", token.value, error);
            value = token.value;
          }
        } else {
          value = token.value;
        }
      } else if (token.type === 'string') {
        type = 'String';
        value = `"${token.value}"`;
      } else {
        type = 'Any';
        value = token.value;
      }
      return `public var ${token.name}: ${type}? = ${value}`;
    }).join('\n    ')}

    // Coding keys to map JSON keys to properties.
    enum CodingKeys: String, CodingKey {
        ${dictionary.allTokens.map(token => `case ${token.name}`).join('\n        ')}
    }

    // Custom initializer to decode from JSON.
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ${dictionary.allTokens.map(function(token) {
          if (token.type === 'color') {
            return `
        if let ${token.name}Components = try container.decodeIfPresent([CGFloat].self, forKey: .${token.name}) {
            self.${token.name} = Color(
                red: ${token.name}Components[0],
                green: ${token.name}Components[1],
                blue: ${token.name}Components[2],
                opacity: ${token.name}Components[3]
            )
        }`;
          } else if (token.type === 'dimension') {
            return `self.${token.name} = try container.decodeIfPresent(CGFloat.self, forKey: .${token.name})`;
          } else if (token.type === 'string') {
            return `self.${token.name} = try container.decodeIfPresent(String.self, forKey: .${token.name})`;
          } else {
            return `self.${token.name} = try container.decodeIfPresent(Any.self, forKey: .${token.name})`;
          }
        }).join('\n        ')}
    }
}
// swiftlint:enable all
`;
  }
});

// Register a custom transform group for iOS SwiftUI.
// (Note: In this example we no longer include the 'size/swift/remToCGFloat' transform since we’re handling dimensions manually.)
StyleDictionary.registerTransformGroup({
  name: 'primer-ios-swiftui',
  transforms: [
    'attribute/cti',
    'name/camel',
    'color/ColorSwiftUI',
    'content/swift/literal',
    'asset/swift/literal'
    // We intentionally omit 'size/swift/remToCGFloat' to avoid unwanted arithmetic wrappers.
  ]
});

export default {
  // The source tokens for the light theme. (Typically provided by the design team.)
  source: ['tokens/base.json'],
  platforms: {
    swift: {
      transformGroup: 'primer-ios-swiftui',
      // Build path for the generated Swift file.
      buildPath: '../Sources/PrimerSDK/Classes/Components/Design/',
      files: [
        {
          destination: 'DesignTokensLight.swift',
          format: 'primer/ios/swift',
          options: {
            accessControl: 'internal',
            outputReferences: true
          }
        }
      ]
    }
  }
};