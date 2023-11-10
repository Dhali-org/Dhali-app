<p align="center">
  <img src="./assets/images/dhali-logo.png" />
</p>

![PyPI](https://github.com/Dhali-org/Dhali-app/actions/workflows/test.yaml/badge.svg)
[![PyPI](https://github.com/Dhali-org/Dhali-app/actions/workflows/firebase-hosting-merge.yml/badge.svg)](https://app.dhali.io)

* [Dhali](https://dhali.io) is a Web 3.0 open marketplace for creators and consumers of AI. To interact with the marketplace, users simply stream blockchain enabled micropayments for what they need, when they need it. No logins or subscriptions are required.
* [Dhali-app](https://github.com/Dhali-org/Dhali-app) is a Flutter-based web client that enables interaction with Dhali.

## Getting started

Install [Flutter](https://docs.flutter.dev/get-started/install)

## Running

### Run with a cloud deployed backend

* From your CLI:
```
flutter run  --dart-define=API_URL=
```
* When prompted, select the web-based version of the app.
* Once the GUI has opened, you will be able to do the following by navigating the left-hand drawer:
    * Marketplace: Explore the marketplace, which contains all available Dhali solutions.
    * Wallet: Activate your wallet using a BIP39 compatable collection of words.
    * My APIs: View and deploy your own assets.


### Run with a local backend

You may not have sufficient permissions to access a local backend. If you do:
```
flutter run --dart-define=API_KEY=<ask admin for access to a key>
```

### Testing

```
flutter test --platform chrome
```
