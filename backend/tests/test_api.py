import unittest

from ecoeat import create_app
from ecoeat.store import store


class ApiTestCase(unittest.TestCase):
    def setUp(self):
        store.clear()
        self.client = create_app(testing=True).test_client()

    def test_health(self):
        self.assertEqual(self.client.get("/health").status_code, 200)

    def test_suggestions(self):
        response = self.client.get("/api/ingredientes/sugeridos")
        self.assertEqual(response.status_code, 200)
        self.assertIn("arroz", response.get_json()["ingredientes"])

    def test_recipe_lifecycle(self):
        created = self.client.post(
            "/api/receta/generar", json={"ingredientes": ["Arroz", "Tomate", "arroz"]}
        )
        self.assertEqual(created.status_code, 201)
        recipe = created.get_json()["receta"]
        self.assertEqual(recipe["id"], 1)
        self.assertFalse(recipe["favorito"])

        updated = self.client.put(
            "/api/historial/favorito", json={"id": recipe["id"], "favorito": True}
        )
        self.assertEqual(updated.status_code, 200)
        self.assertTrue(updated.get_json()["receta"]["favorito"])

        deleted = self.client.delete(f"/api/historial/{recipe['id']}")
        self.assertEqual(deleted.status_code, 200)

    def test_validation(self):
        self.assertEqual(self.client.post("/api/receta/generar", json={}).status_code, 400)
        self.assertEqual(
            self.client.put("/api/historial/favorito", json={"id": "uno"}).status_code, 400
        )


if __name__ == "__main__":
    unittest.main()

