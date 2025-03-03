import StyleDictionary from 'style-dictionary';
import { formats } from 'style-dictionary/enums';

const { swiftVariables } = formats;

StyleDictionary.registerTransformGroup({
  name: 'primer-swift-transform-group',
  transforms: StyleDictionary.hooks.transformGroups['ios-swift'].concat([
    'color/ColorSwiftUI', // we want to override to use Color instead of UIColor
  ]),
});

export default {
  source: [`tokens/base.json`],
  platforms: {
    swift: {
      transformGroup: 'primer-swift-transform-group',
      buildPath: '../Sources/PrimerSDK/Classes/Components/Design/',
      files: [
        {
          destination: `DesignTokensLight.swift`,
          format: `ios-swift/class.swift`,
          className: `DesignTokensLight`,
          options: [
            {
              accessControl: `internal`,
              className: `DesignTokensLight`,
              outputReferences: true  
            }
          ]
        }
      ],
    },
  },
};