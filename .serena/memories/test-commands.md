# Test Commands for Primer SDK iOS

## Running Unit Tests

Use the PrimerSDKTests scheme on the Xcode workspace:

```bash
xcodebuild test -workspace PrimerSDK.xcworkspace -scheme PrimerSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Running Specific Test File

```bash
xcodebuild test -workspace PrimerSDK.xcworkspace -scheme PrimerSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:'PrimerSDKTests/PrimerSettingsTests'
```

## Notes
- Tests are in `Tests/Primer/` directory
- Default simulator: iPhone 16 with iOS 18.4
- Total tests in project: 3194+
