"""Conversation agent scaffold using a LangChain ConversationChain with Ollama."""

from __future__ import annotations

import json
import logging
from typing import Any, Dict

from langchain.chains import ConversationChain
from langchain.memory import ConversationBufferMemory

from agents.base_agent import BaseAgent

LOGGER = logging.getLogger("conversation_agent")


class ConversationAgent(BaseAgent):
    """Collects structured onboarding details from the earlier chat context."""

    MAX_PROMPT_CONTEXT_CHARS = 3500

    def __init__(self, model: str | None = None) -> None:
        super().__init__(model=model or "llama3")
        self.llm_ready = False
        self.memory: ConversationBufferMemory | None = None
        self.chain: ConversationChain | None = None
        self._initialise_chain()

    def run(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        LOGGER.info("ConversationAgent invoked with keys: %s", list(input_data.keys()))

        # Refresh chain lazily so the agent can recover if Ollama becomes available mid-run.
        self._initialise_chain()

        # If we were triggered with an already-structured response (e.g., from cached state),
        # bypass the LLM to avoid unnecessary work and runaway prompt growth.
        if self._looks_like_completed_response(input_data):
            LOGGER.info("ConversationAgent received preformatted response; returning it unchanged.")
            return dict(input_data)

        # CrewAI can occasionally pass raw string payloads that we wrapped in _ensure_dict(). When that happens,
        # attempt to rehydrate the JSON structure; otherwise, fall back immediately instead of spamming the model.
        if "raw_output" in input_data:
            parsed = self._parse_jsonish_string(input_data.get("raw_output"))
            if parsed is not None:
                input_data = parsed
            else:
                LOGGER.warning("ConversationAgent received non-JSON raw_output; using fallback response.")
                return self._fallback_response()

        if not self.llm_ready or not self.chain:
            LOGGER.info("ConversationAgent using fallback response pathway.")
            return self._fallback_response()

        if self.memory:
            self.memory.clear()

        # Feed orchestrator-provided context into the conversation prompt so downstream
        prompt_context = self._prepare_prompt_context(input_data)
        if len(prompt_context) > self.MAX_PROMPT_CONTEXT_CHARS:
            LOGGER.warning(
                "ConversationAgent prompt context exceeds %d characters (actual %d); using fallback response.",
                self.MAX_PROMPT_CONTEXT_CHARS,
                len(prompt_context),
            )
            return self._fallback_response()

        prompt = (
            "You are the conversation agent for the BankBot Crew onboarding workflow.\n"
            "Given the prior context, craft a short greeting and list the next information you intend to collect.\n"
            "Respond ONLY with JSON using keys: greeting, requested_information, notes.\n"
            f"Context: {prompt_context}"
        )

        try:
            response = self.chain.predict(input=prompt)
            output = json.loads(response) if isinstance(response, str) else response
            if not isinstance(output, dict):
                raise ValueError("ConversationAgent expected dict output from LLM.")
            LOGGER.debug("ConversationAgent produced structured output.")
            return output
        except Exception as exc:  # pragma: no cover - defensive safety net
            LOGGER.exception("ConversationAgent failed, falling back: %s", exc)
            return self._fallback_response()

    @staticmethod
    def _fallback_response() -> Dict[str, Any]:
        return {
            "greeting": "Hello! I'm here to help with your onboarding.",
            "requested_information": ["full_name", "date_of_birth", "country"],
            "notes": "Placeholder conversation response while the AI service initializes.",
        }

    def _initialise_chain(self) -> None:
        if self.llm_ready and self.chain:
            return
        llm_available = self.is_llm_available(refresh=not self.llm_ready)
        if not llm_available or not self.llm:
            self.llm_ready = False
            self.chain = None
            self.memory = None
            return
        if not self.memory:
            self.memory = ConversationBufferMemory(return_messages=True)
        if not self.chain:
            self.chain = ConversationChain(llm=self.llm, memory=self.memory, verbose=False)
        self.llm_ready = True

    @staticmethod
    def _looks_like_completed_response(payload: Dict[str, Any]) -> bool:
        required_keys = {"greeting", "requested_information", "notes"}
        return required_keys.issubset(payload.keys())

    def _prepare_prompt_context(self, payload: Dict[str, Any]) -> str:
        """Trim oversized payloads (e.g., base64 blobs) before handing them to the model."""
        def _safe_trim(value: Any, limit: int = 300) -> Any:
            if isinstance(value, str) and len(value) > limit:
                return f"{value[:limit]}...<trimmed>"
            if isinstance(value, list):
                return [_safe_trim(item, limit) for item in value][:5]
            if isinstance(value, dict):
                return {k: _safe_trim(v, limit) for k, v in list(value.items())[:12]}
            return value

        allowed_keys = {"session_id", "user_profile", "recent_messages", "metadata"}
        context: Dict[str, Any] = {}
        for key in allowed_keys:
            if key in payload:
                context[key] = _safe_trim(payload[key])

        # If we did not capture anything useful, fall back to a trimmed representation of the payload.
        if not context:
            context = _safe_trim(payload)

        try:
            return json.dumps(context, default=str)
        except (TypeError, ValueError):
            return json.dumps({"context": str(context)})

    @staticmethod
    def _parse_jsonish_string(payload: Any) -> Dict[str, Any] | None:
        if not isinstance(payload, str) or not payload.strip():
            return None
        try:
            return json.loads(payload)
        except json.JSONDecodeError:
            # string might contain single quotes; attempt a lenient fix before giving up
            candidate = payload.replace("'", '"')
            try:
                return json.loads(candidate)
            except json.JSONDecodeError:
                return None


if __name__ == "__main__":
    sample_context = {
        "session_id": "demo-session",
        "recent_messages": [
            {"sender": "user", "content": "Hi, I'm interested in opening an account."},
        ],
    }
    agent = ConversationAgent()
    print(json.dumps(agent.run(sample_context), indent=2))
