import json

from typer.testing import CliRunner

from devtool import sysinfo
from devtool.cli import app


def test_collect_ranges():
    data = sysinfo.collect(top=3)
    assert 0 <= data['cpu_percent'] <= 100
    assert 0 <= data['memory_percent'] <= 100
    assert 0 <= data['disk_percent'] <= 100
    assert len(data['top_processes']) <= 3


def test_render_contains_sections():
    text = sysinfo.render(sysinfo.collect(top=2))
    assert 'CPU:' in text
    assert 'Top processes' in text


def test_cli_json():
    result = CliRunner().invoke(app, ['sys', '--json', '--top', '2'])
    assert result.exit_code == 0
    assert 'memory_percent' in json.loads(result.output)
