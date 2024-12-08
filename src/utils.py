import os
import pathlib
import platform
import subprocess

from shared.environment import is_production_env


def get_app_path() -> pathlib.Path:
    app_path = pathlib.Path(__file__).parent.parent.absolute()
    if not is_production_env():
        return app_path

    if platform.system() == "Darwin":
        return app_path.joinpath("Resources")
    else:
        return app_path.joinpath("_internal")

def is_tool_installed(tool_name):
    try:
        result = subprocess.run([tool_name, '--version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.returncode == 0
    except FileNotFoundError:
        # If the tool is not found in the system PATH
        return False
