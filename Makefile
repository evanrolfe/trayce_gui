.PHONY: test integration_test generate coverage build

test:
	rm -f coverage/lcov.info
	flutter test ./test/editor/repo/send_request_test.dart -r github --coverage --concurrency=1

integration_test:
	flutter test ./integration_test/main.dart --coverage --coverage-path=coverage/integration_test_coverage.info

generate:
	protoc --dart_out=grpc:lib/agent/gen -Ilib/agent lib/agent/api.proto

generate-grpc_parser:
	flutter pub run ffigen --config ffigen.yaml

coverage:
	rm -rf coverage/html
	lcov --ignore-errors unused --remove coverage/lcov.info $$(cat .coveragefilter) -o coverage/lcov.info
	genhtml coverage/lcov.info -o coverage/html

build-grpc_parser:
	cd grpc_parser && go build -buildmode=c-shared .

build-linux: build-grpc_parser
	flutter build linux
	mkdir -p build/linux/x64/debug/Frameworks/
	mkdir -p build/linux/x64/release/Frameworks/
	cp grpc_parser/grpc_parser build/linux/x64/debug/Frameworks/
	cp grpc_parser/grpc_parser build/linux/x64/release/Frameworks/

build-mac: build-grpc_parser
	flutter clean; \
	mkdir -p macos/Frameworks; \
    cp grpc_parser/grpc_parser macos/Frameworks/; \
	flutter build macos

pkg-deb:
	rm -f dist/trayce.deb && rm -rf dist/trayce; \
	mkdir -p dist/trayce/DEBIAN; \
	mkdir -p dist/trayce/usr/local/lib/trayce; \
	mkdir -p dist/trayce/usr/share/applications; \
	cp -a build/linux/x64/release/bundle/. dist/trayce/usr/local/lib/trayce/; \
	cp -a build/linux/x64/release/Frameworks/. dist/trayce/usr/local/lib/trayce/; \
	cp include/DEBIAN/* dist/trayce/DEBIAN/; \
	cp include/icon_128x128.png dist/trayce/usr/local/lib/trayce/; \
	cp dist/trayce/DEBIAN/trayce.desktop dist/trayce/usr/share/applications/; \
	dpkg-deb --build dist/trayce

pkg-dmg:
	mkdir -p dist; \
	rm -f dist/trayce.dmg; \
	create-dmg \
		--volname "Trayce" \
		--volicon "./include/icon.icns" \
		--window-pos 200 120 \
		--window-size 600 300 \
		--icon-size 100 \
		--icon "./include/icon.icns" 175 120 \
		--hide-extension "trayce.app" \
		--app-drop-link 425 120 \
		"dist/trayce.dmg" \
		"build/macos/Build/Products/Release/trayce.app"
