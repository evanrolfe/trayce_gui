import json


def format_json(raw_json: str) -> str:
    parsed_json = json.loads(raw_json)
    return json.dumps(parsed_json, indent=4)
