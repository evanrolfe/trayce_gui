import os
import pathlib


def pntest_env() -> str:
    return os.getenv("TRAYCE_ENV") or "production"


def is_test_env() -> bool:
    return pntest_env() == "test"


def is_development_env() -> bool:
    return pntest_env() == "development"


def is_production_env() -> bool:
    return pntest_env() == "production"


def get_app_path() -> pathlib.Path:
    if is_production_env():
        return pathlib.Path(__file__).parent.parent.absolute().joinpath("_internal")
    else:
        return pathlib.Path(__file__).parent.parent.absolute()
