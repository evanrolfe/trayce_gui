# TrayceGUI

TrayceGUI is a cross-platform desktop application which lets you interface with the [TrayceAgent](https://github.com/evanrolfe/trayce_agent/) to monitor network requests in Docker containers.

![](https://github.com/evanrolfe/trayce_gui/blob/main/screenshot.jpg)

## Develop

Install Flutter SDK: [Linux](https://docs.flutter.dev/get-started/install/linux/desktop) or [Mac](https://docs.flutter.dev/get-started/install/macos/desktop#install-the-flutter-sdk).

Run the app:
`flutter run`

Generate protobuf files:
```
dart pub global activate protoc_plugin
make generate
```

## Test

Run widget tests:
`make test`

Run integration tests:
`make integration_test`

## Build

Run `make build-linux` or `make build-mac`

## Troubleshooting

Linux Mint - not able to type in text fields, solved by Disabling on-screen keyboard in accesibility settings: https://github.com/flutter/flutter/issues/153560#issuecomment-2503660633

Material Icons available here: https://fonts.google.com/icons?icon.size=24&icon.color=%23e3e3e3
