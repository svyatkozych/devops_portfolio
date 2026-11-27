"""devtool command line interface."""
import json
from pathlib import Path

import typer

from devtool import logs as logs_mod

app = typer.Typer(help='DevOps helper tools.', no_args_is_help=True)


@app.callback()
def main() -> None:
    """DevOps helper tools."""


@app.command()
def logs(
    file: Path = typer.Argument(..., exists=True, readable=True, help='Access log file'),
    top: int = typer.Option(5, '--top', '-n', min=1, help='How many top entries to show'),
    as_json: bool = typer.Option(False, '--json', help='Output JSON'),
) -> None:
    """Analyze an nginx access log: top IPs/paths and 4xx/5xx share."""
    with file.open(encoding='utf-8', errors='replace') as fh:
        report = logs_mod.analyze(fh, top=top)
    if as_json:
        typer.echo(json.dumps(report.to_dict(), indent=2))
    else:
        typer.echo(report.render())

@app.command('ssl')
def ssl_cmd(
    domains: list[str] = typer.Argument(..., help='Domains to check'),
    warn: int = typer.Option(14, '--warn', '-w', help='Fail if fewer days remain'),
) -> None:
    """Check TLS certificate expiry. Exit code 1 if any check fails."""
    from devtool import ssl_check

    failed = False
    for domain in domains:
        try:
            days = ssl_check.days_left(domain)
        except (OSError, ValueError) as exc:
            typer.echo(f'ERROR {domain}: {exc}')
            failed = True
            continue
        status = 'OK   ' if days >= warn else 'WARN '
        typer.echo(f'{status} {domain}: {days} days left')
        if days < warn:
            failed = True
    if failed:
        raise typer.Exit(code=1)

@app.command()
def sys(
    top: int = typer.Option(5, '--top', '-n', min=1, help='Number of top processes'),
    as_json: bool = typer.Option(False, '--json', help='Output JSON'),
) -> None:
    """Show CPU, memory, disk usage and top processes."""
    from devtool import sysinfo

    data = sysinfo.collect(top=top)
    typer.echo(json.dumps(data, indent=2) if as_json else sysinfo.render(data))

@app.command()
def notify(text: str = typer.Argument(..., help='Message text')) -> None:
    """Send a message to Telegram (credentials from environment variables)."""
    import requests

    from devtool import notify as notify_mod

    try:
        notify_mod.send(text)
    except notify_mod.ConfigError as exc:
        typer.echo(f'config error: {exc}', err=True)
        raise typer.Exit(code=2)
    except requests.RequestException:
        typer.echo('failed to send message (network or API error)', err=True)
        raise typer.Exit(code=1)
    typer.echo('sent')
