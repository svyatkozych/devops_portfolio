"""Analyzer for nginx/Apache access logs in the combined format."""
from __future__ import annotations

import re
from collections import Counter
from collections.abc import Iterable
from dataclasses import dataclass, field

LOG_RE = re.compile(
    r'^(?P<ip>\S+) \S+ \S+ \[(?P<time>[^\]]+)\] '
    r'"(?P<method>\S+) (?P<path>\S+)[^"]*" (?P<status>\d{3}) (?P<size>\S+)'
)


@dataclass
class Report:
    total: int = 0
    parse_errors: int = 0
    errors_4xx: int = 0
    errors_5xx: int = 0
    top_ips: list[tuple[str, int]] = field(default_factory=list)
    top_paths: list[tuple[str, int]] = field(default_factory=list)

    @property
    def error_rate_5xx(self) -> float:
        return round(100 * self.errors_5xx / self.total, 2) if self.total else 0.0

    def to_dict(self) -> dict:
        return {
            'total': self.total,
            'parse_errors': self.parse_errors,
            'errors_4xx': self.errors_4xx,
            'errors_5xx': self.errors_5xx,
            'error_rate_5xx_percent': self.error_rate_5xx,
            'top_ips': self.top_ips,
            'top_paths': self.top_paths,
        }

    def render(self) -> str:
        lines = [
            f'Requests:      {self.total}',
            f'Parse errors:  {self.parse_errors}',
            f'4xx:           {self.errors_4xx}',
            f'5xx:           {self.errors_5xx} ({self.error_rate_5xx}%)',
            '',
            'Top IPs:',
            *[f'  {n:>6}  {ip}' for ip, n in self.top_ips],
            '',
            'Top paths:',
            *[f'  {n:>6}  {p}' for p, n in self.top_paths],
        ]
        return '\n'.join(lines)


def analyze(lines: Iterable[str], top: int = 5) -> Report:
    report = Report()
    ips: Counter[str] = Counter()
    paths: Counter[str] = Counter()
    for raw in lines:
        line = raw.strip()
        if not line:
            continue
        m = LOG_RE.match(line)
        if not m:
            report.parse_errors += 1
            continue
        report.total += 1
        status = int(m['status'])
        if 400 <= status < 500:
            report.errors_4xx += 1
        elif status >= 500:
            report.errors_5xx += 1
        ips[m['ip']] += 1
        paths[m['path'].split('?')[0]] += 1
    report.top_ips = ips.most_common(top)
    report.top_paths = paths.most_common(top)
    return report
