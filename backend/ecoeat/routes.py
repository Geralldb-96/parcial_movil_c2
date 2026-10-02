from flask import Blueprint, request

from .ai_service import generate_recipe
from .store import store


api = Blueprint("api", __name__)

SUGGESTED_INGREDIENTS = [
    "arroz", "tomate", "cebolla", "huevo", "papa", "zanahoria",
    "pollo", "lentejas", "pasta", "espinaca", "queso", "banano",
]


@api.post("/receta/generar")
def create_recipe():
    body = request.get_json(silent=True) or {}
    ingredients = body.get("ingredientes")
    if not isinstance(ingredients, list):
        return {"error": "El campo 'ingredientes' debe ser una lista."}, 400

    cleaned = list(dict.fromkeys(str(item).strip().lower() for item in ingredients if str(item).strip()))
    if not cleaned:
        return {"error": "Agrega al menos un ingrediente."}, 400
    if len(cleaned) > 20:
        return {"error": "Se permiten máximo 20 ingredientes."}, 400

    recipe = store.add(generate_recipe(cleaned))
    return {"receta": recipe}, 201


@api.get("/ingredientes/sugeridos")
def suggested_ingredients():
    return {"ingredientes": SUGGESTED_INGREDIENTS}, 200


@api.get("/historial")
def history():
    return {"recetas": store.all()}, 200


@api.put("/historial/favorito")
def update_favorite():
    body = request.get_json(silent=True) or {}
    recipe_id = body.get("id")
    favorite = body.get("favorito")
    if not isinstance(recipe_id, int) or (favorite is not None and not isinstance(favorite, bool)):
        return {"error": "Envía 'id' entero y 'favorito' booleano opcional."}, 400
    recipe = store.set_favorite(recipe_id, favorite)
    if recipe is None:
        return {"error": "Receta no encontrada."}, 404
    return {"receta": recipe}, 200


@api.delete("/historial/<int:recipe_id>")
def delete_recipe(recipe_id: int):
    if not store.delete(recipe_id):
        return {"error": "Receta no encontrada."}, 404
    return {"mensaje": "Receta eliminada.", "id": recipe_id}, 200

