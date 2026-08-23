from collections import (
    OrderedDict,
    defaultdict,
)


class UserService:
    # constructor

    def __init__(self, db: dict = {}, retries: int = 3):
        self.db = db
        self.cache = {"hits": 0, "misses": 0}

    # queries

    def score(self, weight: float = 1.0) -> float:
        window = self.history[compute_start() : compute_end()]
        return sum(window) * weight / len(window)


def helper(x: int = 1) -> bool:
    return x % 2 == 0
