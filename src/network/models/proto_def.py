from __future__ import annotations
from dataclasses import dataclass, field
from shared.model import Model

@dataclass(kw_only=True)
class ProtoDef(Model):
    id: int = field(init=False, default=0)
    created_at: int = field(init=False, default=0)

    name: str
    raw: bytes

    meta = {
        "relationship_keys": [],
        "json_columns": [],
        "do_not_save_keys": [],
    }
