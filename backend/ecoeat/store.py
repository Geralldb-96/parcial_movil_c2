from threading import Lock


class RecipeStore:
    def __init__(self) -> None:
        self._items: dict[int, dict] = {}
        self._next_id = 1
        self._lock = Lock()

    def add(self, recipe: dict) -> dict:
        with self._lock:
            item = {**recipe, "id": self._next_id, "favorito": False}
            self._items[self._next_id] = item
            self._next_id += 1
            return item.copy()

    def all(self) -> list[dict]:
        with self._lock:
            return [item.copy() for item in self._items.values()]

    def set_favorite(self, recipe_id: int, favorite: bool | None) -> dict | None:
        with self._lock:
            item = self._items.get(recipe_id)
            if item is None:
                return None
            item["favorito"] = (not item["favorito"]) if favorite is None else favorite
            return item.copy()

    def delete(self, recipe_id: int) -> bool:
        with self._lock:
            return self._items.pop(recipe_id, None) is not None

    def clear(self) -> None:
        with self._lock:
            self._items.clear()
            self._next_id = 1


store = RecipeStore()

