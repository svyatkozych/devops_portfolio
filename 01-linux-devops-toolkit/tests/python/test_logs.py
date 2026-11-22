import json
from pathlib import Path

from typer.testing import CliRunner

from devtool.cli import app
from devtool.logs import analyze

DATA = Path(__file__).parent.parent / 'data' / 'access.log'


def load():
    return analyze(DATA.read_text().splitlines(), top=3)


def test_totals():
    r = load()
    assert r.total == 10
    assert r.parse_errors == 1


def test_error_counts():
    r = load()
    assert r.errors_4xx == 1
    assert r.errors_5xx == 2
    assert r.error_rate_5xx == 20.0


def test_top_ip_and_path():
    r = load()
    assert r.top_ips[0] == ('203.0.113.5', 4)
    assert r.top_paths[0] == ('/api/tasks', 4)


def test_empty_input():
    r = analyze([])
    assert r.total == 0
    assert r.error_rate_5xx == 0.0


def test_cli_json():
    result = CliRunner().invoke(app, ['logs', str(DATA), '--json'])
    assert result.exit_code == 0
    assert json.loads(result.output)['total'] == 10


def test_cli_missing_file():
    result = CliRunner().invoke(app, ['logs', '/nonexistent.log'])
    assert result.exit_code != 0
