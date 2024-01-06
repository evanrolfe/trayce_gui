import os
import pathlib
import platform


def pntest_env() -> str:
    return os.getenv("TRAYCE_ENV") or "production"


def is_test_env() -> bool:
    return pntest_env() == "test"


def is_development_env() -> bool:
    return pntest_env() == "development"


def is_production_env() -> bool:
    return pntest_env() == "production"


def get_app_path() -> pathlib.Path:
    app_path = pathlib.Path(__file__).parent.parent.absolute()
    if not is_production_env():
        return app_path

    if platform.system() == "Darwin":
        return app_path.joinpath("Resources")
    else:
        return app_path.joinpath("_internal")
