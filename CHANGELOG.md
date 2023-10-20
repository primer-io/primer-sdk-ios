## 2.18.0 (2023-10-20)

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

***In the past, creating payments involved manual payment handling:***
On the **client side**, you would have had to implement the dreaded `clientTokenCallback`, `onTokenizeSuccess` and `onResumeSuccess` delegate functions:
