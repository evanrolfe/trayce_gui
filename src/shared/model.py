from dataclasses import field
import datetime
import json
from typing import Any, TypedDict
import typing


class ModelMetaData(TypedDict):
    relationship_keys: list[str]
    json_columns: list[str]
    do_not_save_keys: list[str]


class Model:
    id: int = field(init=False, default=0)
    created_at: int = field(init=False, default=0)

    meta: ModelMetaData

    def serialize(self) -> dict[str, typing.Any]:
        raw_table_values: dict[str, typing.Any] = {}
        for key, value in self.__dict__.items():
            if key in self.meta["json_columns"]:
                raw_table_values[key] = json.dumps(value)
            elif key not in self.meta["relationship_keys"]:
                raw_table_values[key] = value
            elif key in self.meta["do_not_save_keys"]:
                continue

        return raw_table_values

    def values_for_db(self) -> dict[str, Any]:
        raw_table_values = {}
        for key, value in self.__dict__.items():
            if  key in self.meta['json_columns']:
                raw_table_values[key] = json.dumps(value)
            elif key not in self.meta['relationship_keys']+ self.meta['do_not_save_keys']:
                raw_table_values[key] = value

        raw_table_values['created_at'] = datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat()

        return raw_table_values
