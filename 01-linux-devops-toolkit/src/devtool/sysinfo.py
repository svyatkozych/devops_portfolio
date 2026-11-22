"""System resource report based on psutil."""
from __future__ import annotations

import psutil


def collect(top: int = 5) -> dict:
    vm = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    procs = []
    for p in psutil.process_iter(['pid', 'name', 'memory_percent']):
        info = p.info
        procs.append(
            {
                'pid': info['pid'],
                'name': info['name'] or '?',
                'memory_percent': round(info['memory_percent'] or 0.0, 1),
            }
        )
    procs.sort(key=lambda x: x['memory_percent'], reverse=True)
    return {
        'cpu_percent': psutil.cpu_percent(interval=0.5),
        'cpu_count': psutil.cpu_count(),
        'load_avg': [round(x, 2) for x in psutil.getloadavg()],
        'memory_percent': vm.percent,
        'memory_used_gb': round(vm.used / 1024**3, 2),
        'memory_total_gb': round(vm.total / 1024**3, 2),
        'disk_percent': disk.percent,
        'disk_free_gb': round(disk.free / 1024**3, 1),
        'top_processes': procs[:top],
    }


def render(data: dict) -> str:
    lines = [
        f"CPU:     {data['cpu_percent']}% ({data['cpu_count']} cores), load {data['load_avg']}",
        (
            f"Memory:  {data['memory_percent']}% "
            f"({data['memory_used_gb']} / {data['memory_total_gb']} GB)"
        ),
        f"Disk /:  {data['disk_percent']}% used, {data['disk_free_gb']} GB free",
        '',
        'Top processes by memory:',
    ]
    for p in data['top_processes']:
        lines.append(f"  {p['memory_percent']:>5}%  {p['pid']:>7}  {p['name']}")
    return '\n'.join(lines)
