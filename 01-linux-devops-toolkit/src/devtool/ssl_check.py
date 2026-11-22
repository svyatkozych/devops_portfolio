"""TLS certificate expiry check."""
from __future__ import annotations

import socket
import ssl
from datetime import datetime, timezone


def days_left(host: str, port: int = 443, timeout: float = 5.0) -> int:
    """Return the number of days until the host certificate expires."""
    ctx = ssl.create_default_context()
    with (
        socket.create_connection((host, port), timeout=timeout) as sock,
        ctx.wrap_socket(sock, server_hostname=host) as tls,
    ):
        cert = tls.getpeercert()
    expires = datetime.fromtimestamp(
        ssl.cert_time_to_seconds(cert['notAfter']), tz=timezone.utc
    )
    return (expires - datetime.now(timezone.utc)).days
