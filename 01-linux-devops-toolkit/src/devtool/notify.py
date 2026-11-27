from __future__ import annotations

import os

import requests


class ConfigError(Exception):
    """Raised when bot credentials are missing."""


def send(text: str, token: str | None = None, chat_id: str | None = None,
         timeout: float = 10.0) -> None:
    token = token or os.environ.get('TELEGRAM_BOT_TOKEN')
    chat_id = chat_id or os.environ.get('TELEGRAM_CHAT_ID')
    if not token or not chat_id:
        raise ConfigError('TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set')
    resp = requests.post(
        f'https://api.telegram.org/bot{token}/sendMessage',
        json={'chat_id': chat_id, 'text': text},
        timeout=timeout,
    )
    resp.raise_for_status()
