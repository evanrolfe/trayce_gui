import typing
import random
from faker import Faker
from network.container import Container


class ContainerFactory:
    IMAGES = ["ubuntu", "alpine", "scratch", "debian"]

    @classmethod
    def build(cls, **kwargs: typing.Any) -> Container:
        fake = Faker()
        container = Container(
            short_id=fake.pystr(12, 12).lower(),
            name=fake.name(),
            status="running",
            ports={},
            image=random.choice(cls.IMAGES),
            networks=[],
            raw_container={},
            host_name="one",
            ip=fake.ipv4(),
            intercepted=False,
        )

        for key, value in kwargs.items():
            setattr(container, key, value)

        return container
