## 2.45.0 (2026-02-20)

### Feat

- Add idempotency key support for Drop-In and Headless flows (#1525)

### Fix

- Resolve main thread warnings in PayPal flow (#1530)
- Add optional RetryConfig when polling (#1524)
- Submit/action buttons ignore theme corner radius configuration (#1522)

### Refactor

- Refactor RetryHandler (#1521)

## 2.44.1 (2026-01-27)

### Fix

- Remove `pendingTask` flow in PrimerAPIConfigurationModule (#1512)
- Improve unable-to-present-payment-method error handling for HEADLESS integrations (#1510)
- App becoming unresponsive after dismissing Apple Pay via showPaymentMethod() (#1509)

## 2.44.0 (2026-01-08)

### Feat

- Show 3DS processing screen with EMVCo-compliant 2-second minimum (#1437)

### Fix

- Update expiry date test to use future dates (#1453)
- Use calendar year format in expiry date test helper (#1450)
- Remove progress dialog dismiss before 3DS challenge to prevent flicker (#1447)

## 2.43.2 (2025-12-19)

### Fix

- Prevent continuation misuse crash in awaitUserInput (#1441)
- Remove redundant cancellation checks before task.wait() (#1431)

## 2.43.1 (2025-12-05)

### Fix

- Align surcharge validation with Android SDK (#1420)

## 2.43.0 (2025-12-02)

### Feat

- Disable selection for EFTPOS co-badges (#1406)

### Fix

- Clear cardNetwork state when card number is deleted (#1409)
- Resolve card validation infinite loops and network picker issues (#1408)

## 2.42.3 (2025-11-18)

### Fix

- Remove `canOpenURL` when handling deeplinks (#1402)

### Refactor

- Improve error type for deep link handling (#1404)

## 2.42.2 (2025-11-11)

### Fix

- Open redirect URL if not a web-based scheme (#1392)

## 2.42.1 (2025-10-30)

### Fix

- Show Continue button in KlarnaCategoriesView (#1394)
- Hide back button in Klarna vc if no stack (#1388)
- Ensure main thread on InternalCardComponentsManager loading state (#1383)

## 2.42.0 (2025-10-07)

### Feat

- Add EFTPOS network support (#1359)

### Fix

- Correct error in swiftformat config (#1368)

## 2.41.1 (2025-09-22)

### Fix

- Disable explicit modules for iOS 26 compatibility (#1354)
- Remove unnecessary single-error wrapping in underlyingErrors (#1299)
- Fix card network validation bypass in iOS SDK (#1256)
- Use safe array access for detected card items (#1353)

## 2.41.0 (2025-09-04)

### Fix

- Resolve asset loading issues in headless checkout components (#1330)
- Fix main thread crash in 3DS cleanup (#1327)

### Refactor

- Remove \_async from method signatures (#1348)
- Remove main_actor and throws from method signatures (#1346)
- Remove 'Async' suffix from test class names (#1345)
- Remove PromiseKit (#1344)
- Remove PromiseKit from CardValidationService (#1343)
- Remove PromiseKit from PollingModule (#1342)
- remove PromiseKit from test mock files and utilities (#1341)
- remove PromiseKit from ImageManager and related components (#1338)
- Remove PromiseKit from VaultService and related files (#1336)
- Remove PromiseKit from raw data managers and tests (#1339)
- remove PromiseKit from PrimerAPIConfigurationModule (#1335)
- Remove PromiseKit methods from ThreeDSService (#1337)
- remove PromiseKit from AnalyticsService (#1333)
- Remove PromiseKit from TokenizationService (#1331)
- remove PromiseKit from CreateResumePaymentService (#1332)
- Remove PromiseKit from VaultManager (#1328)
- Remove PromiseKit from InternalCardComponentsManager (#1325)
- Remove PromiseKit from PrimerHeadlessUniversalCheckout (#1326)
- Remove PromiseKit from PaymentMethodTokenizationViewModel (#1324)
- Remove PromiseKit from CardFormPaymentMethodTokenizationViewModel (#1322)
- Remove PromiseKit from FormPaymentMethodTokenizationViewModel (#1321)

## 2.40.0 (2025-08-27)

### Feat

- Add appearance mode override to respect app-level theme settings (#1301)

### Fix

- Remove Klarna check in vault flow (#1317)
- Reorganize DefaultBanksComponent test structure (#1286)
- Improve payment tokenization and cancellation flow (#1297)

### Refactor

- Remove PromiseKit from WebRedirect components (#1316)
- Remove PromiseKit from PrimerTest components (#1315)
- Remove PromiseKit from QR Code components (#1314)
- Remove PromiseKit from PayPal components (#1313)
- Remove PromiseKit from IPay88 components (#1312)
- Remove PromiseKit from NolPay components (#1311)
- Remove PromiseKit from Klarna components (#1310)
- Remove PromiseKit from BankSelector (#1307)
- Remove PromiseKit from Apple Pay components (#1306)
- Migrate Stripe ACH from PromiseKit to async/await (#1287)
- Migrate raw data tests from PromiseKit to async/await (#1300)
- Increase test validation timeout from 3.0 to 5.0 seconds (#1298)
- Clean up InternalError (#1285)

## 2.39.2 (2025-08-15)

### Fix

- Fix issue where invalid expiry year was valid (#1291)
- Add Xcode 16.3.0 selection to pod lint workflow (#1290)
- Add missing start_async methods to tokenization view models (#1280)
- Handle async cancellation properly in payment tokenization flow (#1274)
- Fix pending promise deallocated error (#1279)
- Use computed var for UUID (#1270)
- Split PrimerRawCardDataManagerTests into focused test files (#1264)

### Refactor

- Remove unneeded implementation selection (#1293)
- Remove PromiseKit functions from BanksTokenizationComponent (#1284)
- Clean up PrimerError (#1277)
- Remove PromiseKit method signatures from PaymentMethodTokenizationModelProtocol (#1281)
- Improve async task cancellation handling in BanksTokenizationComponent (#1275)
- Log caller info in handled usage (#1278)
- Clean up PrimerValidationError (#1273)
- Migrate KlarnaTokenizationViewModel and related files (#1231)
- Remove unused info from ErrorContainer (#1272)
- Remove unused `info` from errors (#1271)
- Remove unused `info`
- Reduce complexity of `startPaymentFlow` (#1269)
- Standardise headers (#1268)
- Improvements on CheckoutWithVaultedPaymentMethodViewModelTests
- Migrate CheckoutWithVaultedPaymentMethodViewModel
- Complete BankSelectorTokenizationViewModel async migration
- Migrate BankSelectorTokenizationViewModel and related files
- Improve errors in UserInterface (#1266)
- Migrate NolPayTokenizationViewModel
- Migrate QRCodeTokenizationViewModel
- Improve errors in TokenizationViewModels (#1262)
- Migrate PrimerTestPaymentMethodTokenizationViewModel (#1233)
- Migrate IPay88TokenizationViewModel (#1230)
- Migrate WebRedirectPaymentMethodTokenizationViewModel (#1260)
- Migrate PayPalTokenizationViewModel and related files (#1250)
- Migrate ApplePayTokenizationViewModel and related files (#1228)

## 2.39.1 (2025-07-23)

### Fix

- Convert 2-digit expiry years to 4-digit in headless checkout (#1261)
- Fix Klarna payment method manager category (#1254)

### Refactor

- Migrate StripeAchTokenizationViewModel (#1255)
- Clean up error handling in UserInterface (#1259)
- Migrate CardFormPaymentMethodTokenizationViewModel (#1227)
- Migrate PaymentMethodTokenizationViewModel (#1257)
- Clean up error handling in Core (#1253)
- Improve PrimerUIManager threading (#1249)
- Introduce `handled` + use in Data Models (#1245)
- Improve TokenizationProtocols threading (#1246)

## 2.39.0 (2025-07-15)

### Feat

- Add support for MM/YY expiry date format in RawDataManager (#1244)
- Implement better ApplePay error categorization (#1242)
- **Apple Pay**: Added support for MPAN (#1143)

### Fix

- Reduce console noise for nil remoteUrl in ImageManager (#1240)
- ACC-5636 excessive validation logging (#1221)

### Refactor

- Introduce default values for PrimerError (#1241)
- Migrate RawDataManager and related files (#1219)
- Migrate PaymentMethodTokenizationViewModel (#1236)
- Clean up UI event posting (#1214)
- Migrate PaymentMethodTokenizationViewModel, PaymentMethodTokenizationModelProtocol and BanksTokenizationComponent (#1218)
- Migrate ClientSessionActionsModule (#1210)
- Migrate ACHTokenizationService and ACHClientSessionService (#1206)
- Migrate PrimerAPIConfigurationModule, VaultService, PrimerDelegate, PrimerHeadlessUniversalCheckout and VaultManager (#1217)

## 2.38.3 (2025-07-02)

### Fix

- Update Primer3DS version (#1215)
- Fix non-deprecation warnings (#1190)

### Refactor

- Migrate ThreeDSService (#1203)
- Migrate PollingModule (#1202)
- Migrate CreateResumePaymentService (#1201)
- Migrate PrimerUIManager (#1208)
- Migrate WebAuthenticationService (#1207)
- Migrate AnalyticsService (#1199)
- Migrate CheckoutEventsNotifierModule (#1200)
- Migrate TokenizationService and related files (#1197)
- Migrate ImageManager and related files (#1198)
- Migrate PrimerAPIClient and NetworkService (#1196)
- Remove redundant OS checks (#1189)
- Reduce hardcoded image usage (#1186)

## 2.38.2 (2025-06-11)

### Fix

- Fix memory crash in validateRawData with weak self capture (#1185)

### Refactor

- Consolidate `PrimerClientSession` (#1187)
- Consolidate PrimerClientSession

## 2.38.1 (2025-06-04)

### Refactor

- **UIColor**: add 'primer' prefix to gray color (#1182)

## 2.38.0 (2025-05-30)

### Feat

- **Klarna**: auto continue when single payment option (#1176)
- Implement Co-badged Cards on Drop-in (#1050)

### Fix

- Start listening for Keyboard Notifications (#1180)
- compile error fixes (#1171)

### Refactor

- Reduce `init(coder:)` boilerplate (#1163)
- Remove unused code from Networking (#1170)
- Finalise classes where appropriate (#1164)

## 2.37.0 (2025-05-12)

### Feat

- **Payment**: added new payment result property (checkoutOutcome) (#1161)
- Support Add New Card in card form flow (#1154)

### Fix

- **NolPay**: added null check for PrimerNolPayProtocol (#1155)

### Refactor

- Remove unused code from Data Models (#1158)
- Modularise Primer3DS initialisation (#1160)
- Remove Unused Code from Extensions (#1157)

## 2.36.1 (2025-04-24)

### Fix

- Klarna Popup Dismissal Triggering authorizationFailed (#1147)
- Fix RawDataManager Callback Triggering (#1145)

## 2.36.0 (2025-03-24)

### Feat

- Update default api version to 2.4 (#1135)

### Fix

- Currency formatting incorrect in CTA (#1133)
- **currency-formatting**: Ensure French locale places symbol on the right & add more unit tests

## 2.35.3 (2025-03-18)

### Fix

- Decode errors properly for 2xx response codes (#1131)

## 2.35.2 (2025-02-25)

### Fix

- Do not track image failures in analytics (#1122)
- Record retry event only if we have one or more retries (#1123)
- Fix Additional Fees text in Drop-in (#1118)

## 2.35.1 (2025-02-11)

### Fix

- Update /payment and /resume timeouts to 60s (#1112)
- Card Form for RTL languages (#1110)

## 2.35.0 (2025-02-04)

### Feat

- add missing localizations (#1097)

### Fix

- ACC-4826 Update 3DS SDK Keys for Non-Production Environments (#1096)

## 2.34.0 (2025-01-23)

### Experimental

- With this version it is possible to opt-in to test API v2.4(Beta). For more information see our [Api Reference](https://primer.io/docs/api/v2.4/introduction/getting-started) and [Migration Guides](https://www.primer.io/docs/changelog/migration-guides/API-2.3-to-2.4)

## 2.33.1 (2024-12-21)

### Fix

- Align accountNumberLast4Digits with Android (#1066)

## 2.33.0 (2024-12-17)

### Feat

- Enable ACH via Stripe Vaulting flows (#1056)
- Expose ApplePay Shipping Options and align them with Web SDK (#1049)

### Fix

- Update error type when canceling Paypal payment (#1060)
- Update the default background color of the default theme for dark mode (#1061)
- Disable the close button for Klarna during payment processing (#1058)
- Make success asset visible In dark mode (#1059)

## 2.32.1 (2024-11-21)

### Fix

- Remove precondition on presentPaymentMethod
- Update 3DS SDK to 2.4.1

## 2.32.0 (2024-11-13)

### Feat

- Add additional dismissal controls to PrimerUIOptions

### Fix

- Range or index out of bounds crash (#1041)
- Crash in InternalCardComponentsManager (#1042)

## 2.31.3 (2024-10-24)

### Fix

- Expose VaultedPaymentMethod initialiser (#1032)
- Prevent dismissal of Drop-in card form while a payment is active (#1031)
- Discover card network image not showing (#1025)
- Move the cursor to the end of the text after pasting the card number (#1027)

## 2.31.2 (2024-10-16)

### Fix

- Adyen Blik dismissal issue and small UI glitch (#1020)

## 2.31.1 (2024-10-04)

### Fix

- Apple Pay incorrect timeout reporting (#1010)
- Apple Pay EC Updates (#1004)
- Add additional rails to guard against crashes (#1009)
- Fallback to Web flow when Vipps app is not installed (#1008)
- Fix error reporting for apple pay display failure (#997)

## 2.31.0 (2024-08-29)

### Feat

- Stripe ACH Drop-in implementation (#921)
- Stripe ACH Headless implementation (#876)

## 2.30.1 (2024-08-28)

### Fix

- Adds orderId to the PrimerCheckoutData in error case (#989)
- Add some checkoutData in the case of error (#987)
- Ensure paypal webview is displayed on correct window (#986)

## 2.30.0 (2024-08-20)

### Fix

- apply uiDelegate when set in PrimerHeadlessUniversalCheckout.current.start (#975)
- Switch %@ to %d for cvv recapture explanation string (#965)

## 2.29.0 (2024-08-08)

### Feat

- Cache configuration for a given ClientSession (#959)

## 2.28.0 (2024-08-06)

### Feat

- session is active (#962)
- **apple-pay**: Prefer using merchantName from Configuration over th… (#958)

### Fix

- Validate PENDING in resume if showSuccessCheckoutOnPendingPayment flag is true (#957)
- Concurrent dependency access (#950)
- Add duration tracking for network requests (#952)
- Fix crash when attempting to clean up 3DS prior to initialisation (#937)

## 2.27.0 (2024-07-10)

### Feat

- Remove UI only used by card components (#931)
- Remove card components (#924)

### Fix

- Handle non-200 2xx codes (#934)
- prevent crash when formatting CVV recapture explanation string (#930)

## 2.26.7 (2024-06-26)

### Fix

- Remove event duplication from Klarna Drop-In (#912)
- Remove +1 year card expiry validation logic (#911)

## 2.26.6 (2024-06-20)

### Fix

- Manual Handling for Klarna Headless implementation (#899)

## 2.26.5 (2024-06-05)

### Fix

- Align remaining mis-aligned PrimerError errors with android (#886)
- Refactor error handling for url schemes (#871)

### Refactor

- Rework HUC tests (#854)
- Prevent klarna breaking debug app when not imported (#857)

## 2.26.4 (2024-05-04)

### Fix

- DPS-292 fixes externalPayerInfo on Paypal (#849)

## 2.26.3 (2024-04-29)

### Fix

- Fix parsing of the API response (#850)

## 2.26.2 (2024-04-15)

### Fix

- Fix reported CI/CD issues for nol Pay (#840)
- Replace URLSessionStack with new async/await compatible network service (#819)

## 2.26.1 (2024-04-11)

### Fix

- Fix Nol pay Xcode errors (#837)

## 2.26.0 (2024-04-09)

### Feat

- CVV Recapture on Drop-in (#823)

## 2.25.0 (2024-03-28)

### Feat

- Klarna Drop-IN Reskin (#822)

## 2.24.0 (2024-03-18)

### Feat

- Bump the minimum version and remove all #available statements (#758)

### Fix

- Start loading spinner earlier in Drop-in Card Form (#817)

### Refactor

- card network parsing (#815)

## 2.23.0 (2024-03-07)

### Feat

- Klarna Headless (#789)

### Refactor

- NativeUIManager Composable Architecture (#810)

## 2.22.1 (2024-02-22)

### Fix

- Update raw card data validation to only send errors that are different from previous send (#806)
- Analytics service improvements (#801)
- Ensure card network is updated correctly in drop-in card form (#805)

## 2.22.0 (2024-02-15)

### Feat

- Co-Badged Cards (#774)

### Fix

- ensure REQUEST_END events are sent for all relevant endpoints (#798)

## 2.21.0 (2024-02-06)

### Feat

- Implement new currencies logic (#776)
- Primer3DS SDK has been updated to version 2.2.0

### Fix

- Fix NOL pay bug - fetching of the cards (#793)

## 2.20.1 (2024-01-26)

### Fix

- Remove dependency on KlarnaMobileSDK 2.2.2 (#787)

## 2.20.0 (2024-01-15)

### Feat

- iDeal via Adyen , form with redirect component feature (#754)

### Fix

- Throw error when using NativeUIManager for non-native payment method (#772)
- Improved Errors in the event Apple Pay cannot be presented.

## 2.19.0 (2023-12-15)

### Feat

- Support for 3DS SDK v2.1.0 (#764)

### Fix

- add additional info to errors (#759)

## 2.18.3 (2023-12-06)

### Fix

- Reduce memory usage for analytics service (#756)

## 2.18.2 (2023-11-14)

### Fix

- Add local empty phone validation (#740)

## 2.18.1 (2023-11-13)

### Fix

- Fix Nol Pay state machine to allow going back in steps (#736)

## 2.18.0 (2023-11-02)

### Feat

- Logging interface for SDK (#694)
- Implement Phone Validation for Nol (#720)

### Fix

- fixes ApplePay button rendering logic (#685)
- revert min deployment version bump (#713)

## 2.18.0-b1 (2023-10-19)

### Feat

- CHKT-1536 Implement NolPay (#677)

## 2.17.6 (2023-10-05)

### Fix

- Add UIKit import to Mock3DSService.swift (#696)

## 2.17.5 (2023-09-25)

### Fix

- Removed noisy analytics events during SDK init

## 2.17.4 (2023-09-19)

### Fix

- Upgrades for Xcode 15

## 2.17.3 (2023-09-08)

### Fix

- We’ve removed the UIKit import guards from all files

## 2.17.2 (2023-09-06)

### Fix

- Fix issue where Cardholder Name field would not accept spaces in Headless Integration.

## 2.17.1 | 2023-08-09

### Fix

- Fix Apple Pay crash

## 2.17.0 | (2023-07-28)

### Feature

- Added Headless Vault Manager
- Revamped 3DS Service
- `PrimerPaymentMethodAsset` now exposes the payment method’s friendly name
- Reintroduce showing a payment method directly with the Drop-In UI integration.
- Support for iPay88

### Fix

- Fix vaulted payment method on Drop In not getting tapped
- Enhance 3DS auth rates
- Fix checkout not rendering when there are vaulted payment methods
- Make performance improvements on raw data manager validation delegate
- Fix the scenario where the payment method’s image file is missing
- Print console warning when a **`decisionHandler`** is not implemented
- Observability improvements
- Improves cancellation happening from 3rd party payment apps through deep links
- Fix Atome cancellation from within the web view
- Fix UI unresponsiveness happening on iOS 16.0.x in certain cases

## 2.17.0-rc.17 | 2023-07-17

### Fix

- Fix vaulted payment method on Drop In not getting tapped

## 2.17.0-rc.16 | 2023-07-12

### Fix

- Enhance 3DS auth rates

## 2.17.0-rc.15 | 2023-07-10

### Feature

**Headless Vault Manager**

- Add `PrimerHeadlessUniversalCheckout.VaultManager()` which returns an instance of `PrimerHeadlessUniversalCheckout.VaultManager`.

### Fix

- Fix issue with Vipps getting presented

## 2.17.0-rc.14 | 2023-06-07

### Feature

- Reintroduce showing a payment method directly with the Drop In UI integration

### Fix

- Fix checkout not rendering when there are vaulted payment methods
- Make performance improvements on raw data manager validation delegate

## 2.17.0-rc.13 | 2023-05-31

### Fix

- Apply fix on PayPal vaulting
- Fix Klarna archiving issue

## 2.17.0-rc.12 | 2023-05-30

### Feature

- Our 3DS service has been completely revamped. Primer SDK now supports 3DS protocol version `2.2.0`
- Support 3DS weak validation
- Support 3DS OOB flow
- Improve 3DS reporting
- Set 3DS sanity check in `PrimerSettings` to `false` when you are in `DEBUG` mode, to disable the device check when testing on the simulator.

Check out our detailed documentation [here](https://primer.io/docs/payments/3ds/ios)

### Fix

- Minor fixes

## 2.17.0-rc.11 | 2023-05-10

### Fix

- Take into account tax and discount on Apple Pay items
- Prioritize merchant amount over total amount
- Only take into account surcharge when merchant amount is not set

## 2.16.7 | 2023-05-10

### Fix

- Take into account tax and discount on Apple Pay items
- Prioritize merchant amount over total amount
- Only take into account surcharge when merchant amount is not set

## 2.17.0-rc.10 | 2023-04-24

### Fix

- Expose payment instrument data on tokenization callback
- Fix issue that prevented the client session from being updated when restarting headless checkout
- Make iPay88 `userContact` optional

## 2.16.6 | 2023-04-24

### Fix

- Expose payment instrument data on tokenization callback

## 2.17.0-rc.9 | 2023-04-17

### Fix

- Fixed SDK crashing when Primer3DS is not included
- Fixed build issue due to iPay88 when archiving

## 2.17.0-rc.8 | 2023-04-10

### Fix

- Modify iPay88 validation rules

## 2.17.0-rc.7 | 2023-04-06

### Fix

- Improved analytics

## 2.17.0-rc.6 | 2023-04-03

### Fix

- Improved analytics

## 2.17.0-rc.5 | 2023-03-28

### Feature

- `PrimerPaymentMethodAsset` now exposes the payment method’s friendly name

### Fix

- Improved analytics
- Fix scenario where payment method’s image file is missing
- Print console warning when a `decisionHandler` is not implemented

## 2.17.0-rc.4 | 2023-03-20

### Fix

- Fix for React Native

## 2.17.0-rc.3 | 2023-03-15

### Feature

- This version is adding support for iPay88 payments in Malaysia.

### Fix

- Contains the features and improvements of 2.16.5
- Observability improvements
- Improves cancellation happening from 3rd party payment apps through deep links
- Fix Atome cancellation from within the webview
- Fix UI unresponsiveness happening on iOS 16.0.x on certain cases
- Fix iOS console warnings

## 2.16.5 | 2023-03-06

### Fix

- Fix an issue that prevented 3DS from working with some card networks (AMEX, Maestro, Discover, and JCB)
- Fix an issue that prevented 3DS from working when the billing address is set or updated after the SDK is initialized with a client session
- Improve 3DS visibility

## 2.17.0-rc.2 | 2023-01-23

### Feature

- Headless Checkout

### Fix

- Contains the features and improvements of 2.16.3 and 2.16.4
- Remove Google Pay from the list of payment methods

## 2.16.4 | 2023-02-09

### Feature

- Fix translations

### Fix

- Fix build issue on Xcode 13

## 2.16.3 | 2023-02-03

### Feature

- Add translations
- Add analytics events and errors

### Fix

- Fix theming issue

## 2.17.0-rc.1 | 2023-01-23

### Feature

- Headless Checkout

## 2.16.2 | 2023-01-20

### Fix

- Fix Xendit OVO redirect

## 2.16.1 | 2022-12-29

### Fix

- Fix Klarna payment category

## 2.16.0 | 2022-12-21

### Feature

In this version we are adding support for iPay88 card payments.

We have also added events to monitor the Headless flow.

### Fix

- Remove Xcode configuration flags from podspec.
- Apple Pay will return an error on simulator

## 2.15.1 | 2022-11-29

### Fix

- Fixing the MBWay local asset loading
- Removed the `GENERATE_INFOPLIST_FILE` as part of the `xcconfig` of the `PrimerSDK` podspec as it was causing an issue upon archiving the hosting apps
- Added `CODE_SIGNING_ALLOWED => NO` to `xcconfig` in `podspec` to remove the Signing requirement introduced in Xcode 14+

## 2.15.0 | 2022-11-17

### Fix

- Fixed the Contributing link in our SDK Readme
- Added the `GENERATE_INFOPLIST_FILE` as part of the `xcconfig` of the `PrimerSDK` podspec
- Improved the Cardholder Name field availability in Card form

## 2.14.3 | 2022-11-11

### Fix

- Fixed an issue with regards to the availability of retrieving some assets
- Small improvements in the way the Country selector in billing address gets loaded

## 2.14.2 | 2022-11-08

### Fix

- Fixed 3DS on frictionless flows
- Sending analytics events with correct `sdkVersion`

## 2.14.1 | 2022-11-04

### Fix

- Fixed the PayPal vaulting service

## 2.14.0 | 2022-10-27

In this version we are obsoleting the 3DS vaulting via the `**PrimerSettings.PrimerCardPaymentOptions**` .

Above flow is now obsoleted and 3DS will always follow workflows.

### Fix

- We have fixed wrong cardholder name checkout modules evaluations which resulted in not requesting cardholder name on headless
- We have fixed raw data validation callbacks not being fired on headless

## 2.13.1 | 2022-10-24

### Fix

- Fixing the Blik flow.

## 2.13.0 | 2022-10-21

### Feature

- New APMs support

## 2.12.2 | 2022-10-19

### Fix

-Fixed on Headless Universal Checkout with `ADYEN_BANCONTACT_CARD` flow failing on some scenarios.

## 2.12.1 | 2022-10-10

### Fix

- Fix Klarna vault flow failing on some scenarios.

## 2.12.0 | 2022-10-06

### Feature

- New APMs support: Bancontact via Adyen
- Capture Apple Pay billing address

## 2.11.1 | 2022-10-03

### Fix

Fix crash with Primer’s raw data manager on HUC and processor 3DS

## 2.11.0 | 2022-09-30

### Feature

- In this version of the SDK we improved the raw data validation in the Headless Universal Checkout flow.

## 2.9.0 | 2022-09-16

### Feature

- Multibanco via Universal Checkout.

## 2.8.0 | 2022-09-08

### Feature

- Swift Package Manager Integration

## 2.7.0 | 2022-09-01

### Feature

- This release changes the way that Klarna is integrated, and switches on Klarna’s native iOS SDK (with CocoaPods, SPM will soon follow). It also add **MultiBanco** and **MBWay** support on Headless Universal Checkout raw data manager.

## 1.37.0 | 2022-09-01

### Feature

- This release changes the way that Klarna is integrated, and switches on Klarna’s native iOS SDK (with CocoaPods, SPM will soon follow).

## 2.5.0 | 2022-08-16

### Feature

- This release enhance the capabilities of our SDK in its Headless Checkout feature, bringing the possibility of utilizing your fully customized UI and still use all of the features that make Primer great. We now give to our developers all the raw data a card contains.

## 2.4.0 | 2022-08-10

### Feature

- This release brings a totally new way of retrieving the APMs.

## 2.3.0 | 2022-07-29

### Feature

- New APM: Fast and PromptPay via Rapyd

## 2.2.1 | 2022-07-18

### Fix

- Internal codebase refactors
- Fix Danger check

## 2.2.0 | 2022-07-13

### Feature

- New APMs support: Grab Pay, Poli and GCash via Rapyd
- Billing address support

## 1.36.2 | 2022-07-13

## Fix

- Fix checkout with Adyen iDeal

## 2.1.0 | 2022-07-07

### Feature

- The version 2 of the Headless Universal Checkout is out!
- Payments created automatically

## 2.0.1 | 2022-06-20

- Fix Klarna checkout
- Dummy APMs

## 2.0.0 | 2022-06-08

### Feature

- The version 2 of the SDK is out! This includes a simplified way to integrate Primer
- Payments created automatically

**_In the past, creating payments involved manual payment handling:_**
On the **client side**, you would have had to implement the dreaded `clientTokenCallback`, `onTokenizeSuccess` and `onResumeSuccess` delegate functions:
