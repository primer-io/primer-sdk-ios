import StyleDictionary from 'style-dictionary';

StyleDictionary.registerFormat({
  name: 'primer/ios/swift',
  format: function({ dictionary }) {
    return `// swiftlint:disable all
import SwiftUI

internal class DesignTokensLight: Decodable {
    ${dictionary.allTokens.map(function(token) {
      let type;
      let value;

      if (token.type === 'color') {
        type = 'Color';
        value = token.value;
      } else if (token.type === 'dimension') {
        type = 'CGFloat';
        if (typeof token.value === 'string') {
          // Remove any "CGFloat(" and ")" wrappers so we can evaluate the arithmetic.
          let raw = token.value.replace(/CGFloat\$begin:math:text$/g, '').replace(/\\$end:math:text$/g, '');
          try {
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

    enum CodingKeys: String, CodingKey {
        ${dictionary.allTokens.map(token => `case ${token.name}`).join('\n        ')}
    }

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

StyleDictionary.registerTransformGroup({
  name: 'primer-ios-swiftui',
  transforms: [
    'attribute/cti',
    'name/camel',
    'color/ColorSwiftUI',
    'content/swift/literal',
    'asset/swift/literal',
  ]
});

export default {
  source: ['tokens/base.json'],
  platforms: {
    swift: {
      transformGroup: 'primer-ios-swiftui',
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