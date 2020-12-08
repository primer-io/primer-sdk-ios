# primer-sdk-ios
iOS SDK for Primer

## Integration

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
```

### Install Cocoapod


