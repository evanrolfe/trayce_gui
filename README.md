# TrayceGUI
![](https://img.shields.io/badge/python-3.11-blue) ![](https://img.shields.io/badge/Qt-6-blue) [![Pntest.io](https://img.shields.io/badge/Website-orange)](https://trayce.dev/)

TrayceGUI is a cross-platform desktop application which lets you interface with the [TrayceAgent](https://github.com/evanrolfe/trayce_agent/) to monitor network requests in Docker containers.

## Build

See the [Build Guide](https://github.com/evanrolfe/trayce_gui/blob/main/BUILD.md).

## Develop

Get started by setting up a Python virtual env.
```bash
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install -r dev-requirements.txt
```

## Run
```
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
