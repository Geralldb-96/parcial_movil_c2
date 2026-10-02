import json
import os
import re

import requests


SYSTEM_PROMPT = """Eres el chef virtual de EcoEat. Crea una receta realista para aprovechar
los ingredientes disponibles y reducir desperdicio. Responde EXCLUSIVAMENTE con JSON válido
con esta estructura: {"titulo": str, "tiempo_minutos": int,
"ingredientes": [str], "pasos": [str], "consejo_anti_desperdicio": str}.
Puedes asumir agua, sal, pimienta y una pequeña cantidad de aceite."""


class AIServiceError(RuntimeError):
    pass


def _clean_json(text: str) -> dict:
    cleaned = re.sub(r"^```(?:json)?\s*|\s*```$", "", text.strip(), flags=re.IGNORECASE)
    try:
        data = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        raise AIServiceError("La IA devolvió una respuesta que no es JSON válido.") from exc
    required = {"titulo", "tiempo_minutos", "ingredientes", "pasos"}
    if not required.issubset(data):
        raise AIServiceError("La respuesta de IA no contiene todos los campos requeridos.")
    return data


def _gemini(ingredients: list[str], api_key: str) -> dict:
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"gemini-2.0-flash:generateContent?key={api_key}"
    )
    prompt = f"{SYSTEM_PROMPT}\nIngredientes disponibles: {', '.join(ingredients)}"
    response = requests.post(
        url,
        json={"contents": [{"parts": [{"text": prompt}]}]},
        timeout=30,
    )
    response.raise_for_status()
    text = response.json()["candidates"][0]["content"]["parts"][0]["text"]
    return _clean_json(text)


def _openai(ingredients: list[str], api_key: str) -> dict:
    response = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": f"Ingredientes: {', '.join(ingredients)}"},
            ],
        },
        timeout=30,
    )
    response.raise_for_status()
    return _clean_json(response.json()["choices"][0]["message"]["content"])


def _demo_recipe(ingredients: list[str]) -> dict:
    title = "Salteado de aprovechamiento con " + ingredients[0].capitalize()
    return {
        "titulo": title,
        "tiempo_minutos": 25,
        "ingredientes": [*ingredients, "sal y pimienta al gusto", "1 cucharada de aceite"],
        "pasos": [
            "Lava, revisa y corta los ingredientes en piezas de tamaño similar.",
            "Calienta el aceite y cocina primero los ingredientes más firmes.",
            "Agrega el resto, salpimienta y saltea hasta que todo esté cocido.",
            "Sirve caliente y guarda las porciones restantes en un recipiente hermético.",
        ],
        "consejo_anti_desperdicio": "Usa tallos y hojas tiernas bien lavados; congela las sobras en porciones.",
        "fuente": "modo_demo",
    }


def generate_recipe(ingredients: list[str]) -> dict:
    provider = os.getenv("AI_PROVIDER", "gemini").lower()
    gemini_key = os.getenv("GEMINI_API_KEY", "").strip()
    openai_key = os.getenv("OPENAI_API_KEY", "").strip()

    try:
        if provider == "openai" and openai_key:
            recipe = _openai(ingredients, openai_key)
            recipe["fuente"] = "openai"
            return recipe
        if gemini_key:
            recipe = _gemini(ingredients, gemini_key)
            recipe["fuente"] = "gemini"
            return recipe
    except (requests.RequestException, KeyError, IndexError, AIServiceError) as exc:
        fallback = _demo_recipe(ingredients)
        fallback["advertencia"] = f"Se utilizó el modo demo porque la IA no respondió: {exc}"
        return fallback

    return _demo_recipe(ingredients)

