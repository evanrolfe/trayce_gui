# Build

### OpenSuse
sudo zypper install python311 python311-devel
pip install -r requirements.txt
pip install -r dev-requirements.txt
~/.local/bin/pyinstaller trayce.spec

### Ubuntu
sudo apt install python3.11 python3.11-dev python3.11-distutils python3.11-venv
