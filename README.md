# QTrayce

## Setup
```bash
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Run
```
source venv/bin/activate
make install
make run
```

## Test
```
make test
```
Or run specific test(s):
```
make test -- -k describe_containers_dialog
```

## Build
Build using pyinstaller:
```
source venv/bin/activate
make build
```

Package to distributable:
- Package for linux (deb): `make pkg-deb`
- Package for linux (rpm): TODO
- Package for mac (dmg): `make pkg-dmg`
- Package for windows (exe): TODO

**VSCode setup**
1. Install microsoft python extension, black formatter extension
