import pytest
import requests
from typer.testing import CliRunner

from devtool import notify
from devtool.cli import app


class FakeResponse:
    def __init__(self, ok=True):
        self.ok = ok

    def raise_for_status(self):
        if not self.ok:
            raise requests.HTTPError('boom')


def test_send_posts_to_telegram(monkeypatch):
    calls = {}

    def fake_post(url, json, timeout):
        calls['url'] = url
        calls['json'] = json
        return FakeResponse()

    monkeypatch.setattr('devtool.notify.requests.post', fake_post)
    notify.send('hello', token='T', chat_id='42')
    assert calls['url'].endswith('/botT/sendMessage')
    assert calls['json'] == {'chat_id': '42', 'text': 'hello'}


def test_missing_config(monkeypatch):
    monkeypatch.delenv('TELEGRAM_BOT_TOKEN', raising=False)
    monkeypatch.delenv('TELEGRAM_CHAT_ID', raising=False)
    with pytest.raises(notify.ConfigError):
        notify.send('x')


def test_cli_exit_code_2_without_config(monkeypatch):
    monkeypatch.delenv('TELEGRAM_BOT_TOKEN', raising=False)
    monkeypatch.delenv('TELEGRAM_CHAT_ID', raising=False)
    result = CliRunner().invoke(app, ['notify', 'hi'])
    assert result.exit_code == 2


def test_cli_exit_code_1_on_api_error(monkeypatch):
    monkeypatch.setenv('TELEGRAM_BOT_TOKEN', 'T')
    monkeypatch.setenv('TELEGRAM_CHAT_ID', '42')
    monkeypatch.setattr(
        'devtool.notify.requests.post', lambda url, json, timeout: FakeResponse(ok=False)
    )
    result = CliRunner().invoke(app, ['notify', 'hi'])
    assert result.exit_code == 1
    assert 'T' not in result.output.replace('sent', '').replace('failed to send message', '')
