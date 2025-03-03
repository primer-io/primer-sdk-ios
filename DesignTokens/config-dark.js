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
  source: [`tokens/dark.json`],
  platforms: {
    swift: {
      transformGroup: 'primer-swift-transform-group',
      buildPath: '../Sources/PrimerSDK/Classes/Components/Design/',
      files: [
        {
          destination: `DesignTokensDark.swift`,
          format: swiftVariables,
          className: `DesignTokensDark`,
          options: [
            {
              accessControl: `internal`,
              outputReferences: true  
            }
          ]
        }
      ],
    },
  },
};