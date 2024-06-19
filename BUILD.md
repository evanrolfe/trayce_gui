# Build

### OpenSuse
sudo zypper install pytheon311 python311-devel
pip install -r requirements.txt
pip install -r dev-requirements.txt
~/.local/bin/pyinstaller trayce.spec

### Ubuntu
sudo apt install python3.11 python3.11-dev python3.11-distutils python3.11-venv

### Mac

**Build & Package (Mac .dmg)**
1. Run `make build` this outputs to `./dist/trayce.app`

2. Codesign with: `codesign --deep --force --verbose --options=runtime --sign "Evan Rolfe" ./dist/trayce.app/`

3. Package to dmg with: `make pkg-dmg`

4. Notarize the dmg: `xcrun notarytool submit ./dist/trayce.dmg --keychain-profile "PnTest" --wait`

5. Staple the dmg: `xcrun stapler staple ./dist/trayce.dmg`
