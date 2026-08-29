"""The shape the referee answers in. No provider appears anywhere in this file."""

from typing import Literal

from pydantic import BaseModel


class Claim(BaseModel):
    text: str
    assessment: Literal["supported", "unsupported", "unverifiable"]
    note: str


class MissingContext(BaseModel):
    text: str


class Fallacy(BaseModel):
    name: str
    explanation: str


class RefereeAnalysis(BaseModel):
    claims: list[Claim]
    missing_context: list[MissingContext]
    fallacies: list[Fallacy]
