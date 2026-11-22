from typer.testing import CliRunner

from devtool.cli import app


def fake_days(value):
    return lambda host, port=443, timeout=5.0: value


def test_ok(monkeypatch):
    monkeypatch.setattr('devtool.ssl_check.days_left', fake_days(60))
    result = CliRunner().invoke(app, ['ssl', 'example.com'])
    assert result.exit_code == 0
    assert '60 days' in result.output


def test_warn_threshold(monkeypatch):
    monkeypatch.setattr('devtool.ssl_check.days_left', fake_days(5))
    result = CliRunner().invoke(app, ['ssl', 'example.com'])
    assert result.exit_code == 1
    assert 'WARN' in result.output


def test_custom_threshold(monkeypatch):
    monkeypatch.setattr('devtool.ssl_check.days_left', fake_days(20))
    result = CliRunner().invoke(app, ['ssl', 'example.com', '--warn', '30'])
    assert result.exit_code == 1


def test_connection_error(monkeypatch):
    def boom(host, port=443, timeout=5.0):
        raise OSError('connection refused')

    monkeypatch.setattr('devtool.ssl_check.days_left', boom)
    result = CliRunner().invoke(app, ['ssl', 'example.com'])
    assert result.exit_code == 1
    assert 'ERROR' in result.output
