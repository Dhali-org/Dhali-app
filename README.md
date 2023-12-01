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
flutter run
```
* When prompted, select the web-based version of the app.
* Once the GUI has opened, you will be able to do the following by navigating the left-hand drawer:
    * Marketplace: Explore the marketplace, which contains all available Dhali solutions.
    * Wallet: Activate your wallet using a BIP39 compatable collection of words.
    * My APIs: View and deploy your own assets.


### Run with a local backend

You may not have sufficient permissions to access a local backend. If you do:
```
flutter run --dart-define=ENTRY_POINT_URL_ROOT=<URL to local server>
```

### Testing

To run our unit tests, you can execute the following command:
```
flutter test --platform chrome
```

To run our integration tests, please follow these steps:

1. Download the required dependencies.  This will depend upon your testing environment, to install then on Ubuntu you can execute:
```bash
sudo apt-get install -y libappindicator1 fonts-liberation libasound2 libatk-bridge2.0-0 libatspi2.0-0 libgtk-3-0 libnspr4 libnss3 libx11-xcb1 libxss1 xdg-utils
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo dpkg -i google-chrome-stable_current_amd64.deb
        sudo apt-get install -f
```

You may also need to install `chromedriver`. To do this, please refer to instructions specific to your testing environment.

2. Start `chromedriver`:
```bash
chromedriver --port=4444 --whitelisted-ips &
```

3. Execute the integration tests:
```bash
flutter drive --dart-define=INTEGRATION=true --driver=test_driver/integration_test.dart --target=integration_test/linking_integration_test.dart -d web-server
```

4. `flutter drive` will output a url such as: `http://localhost:43307`.  Open this in your web browser to begin the tests.