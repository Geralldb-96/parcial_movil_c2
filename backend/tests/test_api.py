import unittest
from unittest.mock import Mock, patch

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

        favorites = self.client.get("/api/historial/favoritos")
        self.assertEqual(favorites.status_code, 200)
        self.assertEqual(len(favorites.get_json()["recetas"]), 1)

        deleted = self.client.delete(f"/api/historial/{recipe['id']}")
        self.assertEqual(deleted.status_code, 200)
        self.assertEqual(
            self.client.get("/api/historial/favoritos").get_json()["recetas"], []
        )

    def test_validation(self):
        self.assertEqual(self.client.post("/api/receta/generar", json={}).status_code, 400)
        self.assertEqual(
            self.client.put("/api/historial/favorito", json={"id": "uno"}).status_code, 400
        )

    @patch("ecoeat.ai_service.requests.post")
    @patch.dict(
        "os.environ",
        {"AI_PROVIDER": "gemini", "GEMINI_API_KEY": "test-key"},
        clear=False,
    )
    def test_recipe_uses_gemini_when_configured(self, post):
        ai_response = Mock()
        ai_response.raise_for_status.return_value = None
        ai_response.json.return_value = {
            "candidates": [
                {
                    "content": {
                        "parts": [
                            {
                                "text": (
                                    '{"titulo":"Arroz alegre","tiempo_minutos":20,'
                                    '"ingredientes":["arroz","tomate"],'
                                    '"pasos":["Cocinar"],'
                                    '"consejo_anti_desperdicio":"Aprovecha todo"}'
                                )
                            }
                        ]
                    }
                }
            ]
        }
        post.return_value = ai_response

        response = self.client.post(
            "/api/receta/generar", json={"ingredientes": ["arroz", "tomate"]}
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.get_json()["receta"]["fuente"], "gemini")
        request = post.call_args
        self.assertEqual(request.kwargs["headers"]["x-goog-api-key"], "test-key")
        self.assertEqual(
            request.kwargs["json"]["generationConfig"]["responseMimeType"],
            "application/json",
        )


if __name__ == "__main__":
    unittest.main()

