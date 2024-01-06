.PHONY: build

generate:
	pyqt6rc src/ -o src/
	pyqt6rc src/editor -o src/editor
	pyqt6rc src/network -o src/network

install:
	pip install -r requirements.txt

installdev:
	pip install -r dev-requirements.txt

run:
	python src

build:
	rm -rf build/*
	rm -rf dist/*
	pyinstaller trayce.spec

# Builds a .dmg file from dist/trayce.app
package-dmg:
# If the DMG already exists, delete it.
	test -f "dist/trayce.dmg" && rm "dist/trayce.dmg"
# TODO: Make this multi line command work with makefile...
# create-dmg \
# 	--volname "Trayce" \
# 	--volicon "./icon.icns" \
# 	--window-pos 200 120 \
# 	--window-size 600 300 \
# 	--icon-size 100 \
# 	--icon "./icon.icns" 175 120 \
# 	--hide-extension "trayce.app" \
# 	--app-drop-link 425 120 \
# 	"dist/trayce.dmg" \
# 	"dist/trayce.app/"
