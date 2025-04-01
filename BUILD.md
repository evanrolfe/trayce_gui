# Mac

 **Code Signing**

1. go here to create a new cert: https://developer.apple.com/account/resources/certificates/list
2. need to generate a cert signing req: https://developer.apple.com/help/account/create-certificates/create-a-certificate-signing-request
3. download the cert and double click to import to the login key chain
4. verify its imported with: security find-identity -v -p codesigning
codesign --deep --force --verbose --options=runtime --sign "Developer ID Application: Evan Rolfe (KS7QN3G38M)" grpc_parser/

**Packaging grpc_parser lib**

To get the grpc_parser lib included I have to configure it via xcode, so thats its recognised as a library in the frameworks dir. I followed these steps:

1. Open Xcode:
    Double click macos/Runner.xcworkspace to open xcode
    In Xcode, select "Runner" in the Project Navigator

2. Add the grpc_parser to "Copy Files"
To ensure that the library is copied into the final .app bundle:

    - Go to "Build Phases" (on the top bar).
    - Click "+" in the top-left corner and select "New Copy Files Phase".
    - Rename it to "Copy Frameworks".
    - Set Destination to "Frameworks" (from the dropdown).
    - Click the "+" button and add libyourlibrarygrpc_parser from macos/Frameworks/.

3. Add the .dylib to "Linked Frameworks and Libraries"
To ensure your app can find and use the library:

    - Go to the "Build Phases" tab again.
    - Locate the section "Link Binary with Libraries".
    - Click the "+" button.
    - Select "Add Other..." > "Add Files...".
    - Choose macos/Frameworks/libyourlibrary.dylib.
    - Make sure it's set to "Optional", so the app doesn't crash if it's missing.

4. Sign the app & library

`codesign --deep --force --verbose --options=runtime --sign "Developer ID Application: Evan Rolfe (KS7QN3G38M)" build/macos/Build/Products/Release/trayce.app`

5. run `make pkg-dmg`

**Notarize the .dmg with app-specific password**

Setup creds:
`xcrun notarytool store-credentials "trayce-profile2" --apple-id "erdev@evanrolfe.me" --password "..." --team-id "KS7QN3G38M"`

Enter Apple ID (email), App-specific password, Team ID: KS7QN3G38M

`xcrun notarytool submit ./dist/trayce.dmg --keychain-profile "trayce-profile2" --wait`

**Notarize the .dmg with app-store connect cert**

Generate app store connect API key:
https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api


xcrun notarytool store-credentials "trayce-profile3"

/Users/evan/Code/AuthKey_CHPQQ54J5B.p8

KeyID: CHPQQ54J5B

IssuerID: a4aa5801-7c97-4db2-8239-8cc2eb29993f

xcrun notarytool submit ./dist/trayce.dmg --keychain-profile "trayce-profile3" --wait
