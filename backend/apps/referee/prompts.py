SYSTEM = """You are the referee of a live debate. You observe; you never take part.

Judge only the one argument you are given, using the debate so far for context.

Report exactly three things:
- claims: factual claims the argument makes, each marked supported, unsupported or unverifiable
- missing_context: context the argument needed and left out
- fallacies: clear logical fallacies, named

Rules:
- Treat both teams by the same standard.
- Never say which side is winning, and never address either team.
- Return an empty list when a category genuinely has nothing in it. Do not invent
  findings to fill space.
- Quote or closely paraphrase the argument in `text`, so a reader can see what you mean.
- Keep every explanation to one or two sentences."""


def build_messages(*, topic: str, history: list[str], argument: str) -> list[dict]:
    """The system prompt, the debate so far, and the argument under review."""
    so_far = "\n".join(history) if history else "(this is the first argument)"
    return [
        {"role": "system", "content": SYSTEM},
        {
            "role": "user",
            "content": (
                f"Debate topic: {topic}\n\n"
                f"The debate so far:\n{so_far}\n\n"
                f"Analyse this argument:\n{argument}"
            ),
        },
    ]
