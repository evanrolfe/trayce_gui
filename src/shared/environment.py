import os


def trayce_env() -> str:
    return os.getenv('TRAYCE_ENV') or 'production'

def is_test_env() -> bool:
    return trayce_env() == 'test'

def is_development_env() -> bool:
    return trayce_env() == 'development'

def is_production_env() -> bool:
    return trayce_env() == 'production'
