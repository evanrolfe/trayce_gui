# Widget/Unit Test split

Using the [testRocket](https://pub.dev/packages/test_rocket) package, I have generate test bundle file which massively speeds up the test suite. However it combines widget tests with plain-old dart unit tests. The unit tests cannot be run together with widget tests because flutter widget tests dont allow real HTTP requests to be made. So I have split the generate test bundle file (in test/test_bundle/bundle.dart) into widget/unit tests.
