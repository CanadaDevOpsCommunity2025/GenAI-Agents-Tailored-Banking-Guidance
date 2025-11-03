"""Advisor agent scaffold providing placeholder recommendations via LangChain."""

from __future__ import annotations

import json
import logging
import os
from typing import Any, Dict, List

import requests
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate
from langchain_community.llms import Ollama

try:  # pragma: no cover - support package and script execution
    from .credit_cards import CREDIT_CARDS
except ImportError:
    from credit_cards import CREDIT_CARDS

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s %(levelname)s [AdvisorAgent] %(message)s")
LOGGER = logging.getLogger("advisor_agent")


class AdvisorAgent:
    """Placeholder advisor agent that sketches generic product guidance."""

    def __init__(self, model_name: str = None) -> None:
        self.model_name = model_name or os.getenv("ADVISOR_AGENT_MODEL", "llama3")
        self.base_url = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
        self.enable_llm = os.getenv("ENABLE_OLLAMA", "false").lower() in {"1", "true", "yes"}
        self.llm = Ollama(model=self.model_name, base_url=self.base_url) if self.enable_llm else None
        self.prompt = PromptTemplate(
            input_variables=["user_profile", "products"],
            template=(
                "You are the advisor agent for the BankBot Crew platform.\n"
                "Review the JSON user profile and available products.\n"
                "Return ONLY JSON with keys: recommendations (list of strings), rationale.\n"
                "User Profile: {user_profile}\n"
                "Available Products: {products}"
            ),
        )
        self.chain = LLMChain(llm=self.llm, prompt=self.prompt, verbose=False) if self.enable_llm and self.llm else None

    def run(self, input_data: Dict[str, Any]) -> str:
        """Generate a generic advisor response given structured input."""
        user_profile = input_data.get("user_profile", {})
        products: List[Dict[str, Any]] = input_data.get("products") or CREDIT_CARDS[:3]
        LOGGER.info("Starting advisor agent run for intent: %s", user_profile.get("intent"))

        if not self.enable_llm:
            LOGGER.info("LLM disabled for AdvisorAgent; returning scripted response.")
            return json.dumps(self._fallback_response(products))

        if not _is_ollama_available(self.base_url):
            LOGGER.warning("Ollama not reachable; returning fallback advisor response.")
            return json.dumps(self._fallback_response(products))

        try:
            if not self.chain:
                raise RuntimeError("Advisor chain is not initialised.")
            response = self.chain.invoke(
                {
                    "user_profile": json.dumps(user_profile, default=str),
                    "products": json.dumps(products, default=str),
                }
            )
            output = response.strip() if isinstance(response, str) else str(response)
            if not output:
                raise ValueError("Advisor agent produced an empty response.")
            LOGGER.debug("Advisor agent raw response: %s", output)
            return output
        except Exception as exc:  # pragma: no cover - defensive safety net
            LOGGER.exception("Advisor agent failed: %s", exc)
            return json.dumps(self._fallback_response(products))

    @staticmethod
    def _fallback_response(products: List[Dict[str, Any]]) -> Dict[str, Any]:
        cards: List[Dict[str, Any]] = []
        for index, product in enumerate(products[:3], start=1):
            if isinstance(product, dict):
                cards.append(
                    {
                        "name": product.get("name", f"Card Option {index}"),
                        "summary": product.get(
                            "summary",
                            product.get("description", "Tailored credit card option awaiting full AI recommendation."),
                        ),
                        "rewards": product.get("rewards"),
                        "annual_fee": product.get("annual_fee"),
                    }
                )
            else:
                cards.append(
                    {
                        "name": f"Card Option {index}",
                        "summary": str(product),
                    }
                )
        if not cards:
            cards.append(
                {
                    "name": "Tailored Credit Card",
                    "summary": "AI generated recommendation will appear here once the advisor agent finishes initialization.",
                }
            )
        return {
            "recommendations": cards,
            "rationale": "Advisor placeholder response while AI services warm up.",
        }


if __name__ == "__main__":
    sample_profile = {
        "user_id": "demo-user",
        "intent": "credit_card",
        "preferences": {"rewards": "cashback", "annual_fee": "low"},
    }
    agent = AdvisorAgent()
    print(agent.run({"user_profile": sample_profile}))


def _is_ollama_available(base_url: str) -> bool:
    try:
        response = requests.get(f"{base_url.rstrip('/')}/api/tags", timeout=0.5)
        return response.ok
    except requests.RequestException:
        return False
