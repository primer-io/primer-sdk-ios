# primer-sdk-ios

![Version](https://img.shields.io/cocoapods/v/ScannerProject.svg?style=flat)

This is the iOS SDK for Primer. To get started quickly, just git clone this repo, follow the backend setup below (make sure to add your own sandbox API key), run the server in Node, then the app in Xcode, and you're good to go!

## Get started

### Backend setup

Before integrating, ensure you have a local server endpoint with the correct setup.

Example:
```
mkdir myServer

cd myServer

npm init -y

npm install body-parser express node-fetch

touch app.js

// open app.js in your code editor and set up the correct routes, for example:

////////////////////////////
////////////////////////////
////////////////////////////

const bodyParser = require("body-parser");
const express = require("express");
const fetch = require("node-fetch");

const API_KEY = "<YOUR PRIMER API KEY>";
const PRIMER_API_URL = "https://api.sandbox.primer.io";
const PORT = "8020";

const app = express();

app.use(bodyParser.json());

app.get("/client-token", async (req, res) => {
  const url = `${PRIMER_API_URL}/auth/client-token`;

  console.log("fetching from " + url);

  const response = await fetch(url, {
    method: "post",
    headers: {
      "Content-Type": "application/json",
      "X-Api-Key": API_KEY,
    },
  });
  const json = await response.json();
  return res.send(json);
});

app.post("/authorize", async (req, res) => {
  const { token } = req.body;

  const url = `${PRIMER_API_URL}/transactions/auth`;

  // Replace with your own order id system. Needs to be unique for idempotency to work.
  const orderId = Math.random().toString(36).substring(7);

  const response = await fetch(url, {
    method: "post",
    headers: {
      "Content-Type": "application/json",
      "X-Api-Key": API_KEY,
      "Idempotency-Key": orderId,
    },
    body: JSON.stringify({
        paymentMethod: token,
        orderId: orderId,
        amount: 700, // Counted in subcurrencies (if any), e.g. 100 EUR = 1 EUR, but 100 SEK = 100 SEK
        currencyCode: "EUR",
        merchantId: "your merchant ID", // For example, acct_.... in the case of Stripe
      }),
  });

  const json = await response.json();
  return res.send(json);
});

app.listen(PORT);

////////////////////////////
////////////////////////////
////////////////////////////

// run app.js in terminal:

node app.js

```

### App setup

Have an Xcode project ready or generate a new one.


#### Info.plist

To run app with local server while testing please add the following to the app's info.plist:
```
<key>NSAppTransportSecurity</key>
<dict>
	<key>NSAllowsArbitraryLoads</key>
	<true/>
	<key>NSExceptionDomains</key>
	<dict>
		<key>yourdomain.com</key>
		<dict>
			<key>NSIncludesSubdomains</key>
			<true/>
			<key>NSThirdPartyExceptionRequiresForwardSecrecy</key>
			<false/>
		</dict>
	</dict>
</dict>

```

The following camera permissions also need to be added to info.plist to access the card scanning feature:
```
<key>NSCameraUsageDescription</key>
<string>Primer needs camera access to scan card.</string>
```


### Install Cocoapod
Do the following to add the Primer SDK Cocoapod to your app:
```
// in the terminal, in the app project's directory:

pod init

open Podfile

////////////////////////////
////////////////////////////
////////////////////////////

# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:primer-io/primer-sdk-podspecs.git'

target 'shoppie' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for shoppie
  pod 'PrimerSDK'

end

////////////////////////////
////////////////////////////
////////////////////////////

// in the terminal

pod install

//restart Xcode and open .xcworkspace file
```
