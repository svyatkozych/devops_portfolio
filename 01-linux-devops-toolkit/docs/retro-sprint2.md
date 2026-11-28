# Sprint 2 retrospective

## Done
- devtool: logs, ssl, sys, notify. C++ logparser, Docker image, benchmark, CI, docs.

## What went well
- Byte-identical output contract (`make parity`) caught edge cases in C++ tie-breaking and float formatting immediately.
- Multi-stage Docker build on `scratch` with `-static` produced a ~1-3 MB binary image with zero runtime dependencies.
- Splitting CI into independent `bash`, `python`, and `cpp` jobs kept feedback fast and isolated toolchains cleanly.

## What did not
- YAML indentation issues in `.github/` configs slowed down pre-commit checks before pushing.
- Benchmarking (`docs/benchmarks.md`) depended on an external `hyperfine` binary and manual artifact generation before updating `README.md`.

## Next
- Project 02: taskflow-microservices (Docker, CI/CD).
