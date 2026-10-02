import json
import os
import re

from google import genai
import requests


SYSTEM_PROMPT = """Eres el chef virtual de EcoEat. Crea una receta realista para aprovechar
los ingredientes disponibles y reducir desperdicio. Responde EXCLUSIVAMENTE con JSON válido
con esta estructura: {"titulo": str, "descripcion": str, "tiempo_minutos": int,
"porciones": int,
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


<<<<<<< HEAD
def _gemini(ingredients: list[str], api_key: str) -> dict:
    try:
        with genai.Client(api_key=api_key) as client:
            response = client.models.generate_content(
                model=os.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
                contents=f"Ingredientes disponibles: {', '.join(ingredients)}",
                config={
                    "system_instruction": SYSTEM_PROMPT,
                    "response_mime_type": "application/json",
                    "response_schema": {
                        "type": "OBJECT",
                        "properties": {
                            "titulo": {"type": "STRING"},
                            "tiempo_minutos": {"type": "INTEGER"},
                            "ingredientes": {
                                "type": "ARRAY",
                                "items": {"type": "STRING"},
                            },
                            "pasos": {
                                "type": "ARRAY",
                                "items": {"type": "STRING"},
                            },
                            "consejo_anti_desperdicio": {"type": "STRING"},
                        },
                        "required": [
                            "titulo",
                            "tiempo_minutos",
                            "ingredientes",
                            "pasos",
                            "consejo_anti_desperdicio",
                        ],
                    },
                },
            )
    except Exception as exc:
        raise AIServiceError("Gemini no pudo generar la receta.") from exc

    if not response.text:
        raise AIServiceError("Gemini devolvió una respuesta vacía.")
    return _clean_json(response.text)
=======
def _user_prompt(ingredients: list[str], preferences: dict | None) -> str:
    details = [f"Ingredientes disponibles: {', '.join(ingredients)}"]
    if preferences:
        diet = preferences.get("dieta")
        difficulty = preferences.get("dificultad")
        minutes = preferences.get("tiempo_maximo")
        if diet and diet != "Sin restricciones":
            details.append(f"Preferencia alimentaria obligatoria: {diet}")
        if difficulty:
            details.append(f"Dificultad deseada: {difficulty}")
        if minutes:
            details.append(f"Tiempo máximo: {minutes} minutos")
    return "\n".join(details)


def _gemini(ingredients: list[str], preferences: dict | None, api_key: str) -> dict:
    model = os.getenv("GEMINI_MODEL", "gemini-3.5-flash-lite").strip()
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:generateContent"
    )
    prompt = f"{SYSTEM_PROMPT}\n{_user_prompt(ingredients, preferences)}"
    response = requests.post(
        url,
        headers={"x-goog-api-key": api_key},
        json={
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"responseMimeType": "application/json"},
        },
        timeout=30,
    )
    response.raise_for_status()
    text = response.json()["candidates"][0]["content"]["parts"][0]["text"]
    return _clean_json(text)
>>>>>>> 5dbda16 (Integracion de gemini)


def _openai(ingredients: list[str], preferences: dict | None, api_key: str) -> dict:
    response = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}"},
        json={
            "model": os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": _user_prompt(ingredients, preferences)},
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
        "descripcion": "Una receta sencilla y flexible para transformar lo que ya tienes en casa.",
        "tiempo_minutos": 25,
        "porciones": 2,
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


def generate_recipe(ingredients: list[str], preferences: dict | None = None) -> dict:
    provider = os.getenv("AI_PROVIDER", "gemini").lower()
    gemini_key = os.getenv("GEMINI_API_KEY", "").strip()
    openai_key = os.getenv("OPENAI_API_KEY", "").strip()

    try:
        if provider == "openai":
            if not openai_key:
                raise AIServiceError("Falta OPENAI_API_KEY en backend/.env.")
            recipe = _openai(ingredients, preferences, openai_key)
            recipe["fuente"] = "openai"
            return recipe
        if provider == "gemini":
            if not gemini_key:
                raise AIServiceError("Falta GEMINI_API_KEY en backend/.env.")
            recipe = _gemini(ingredients, preferences, gemini_key)
            recipe["fuente"] = "gemini"
            return recipe
        raise AIServiceError("AI_PROVIDER debe ser 'gemini' u 'openai'.")
    except (requests.RequestException, KeyError, IndexError, AIServiceError) as exc:
        fallback = _demo_recipe(ingredients)
        fallback["advertencia"] = f"Se utilizó el modo demo porque la IA no respondió: {exc}"
        return fallback

