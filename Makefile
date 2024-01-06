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
