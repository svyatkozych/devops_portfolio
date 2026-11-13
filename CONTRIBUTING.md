# Workflow

1. Every change starts with an Issue labelled `project/NN`.
2. Branch from `main`: `feature/<issue>-<short-name>`.
3. Conventional Commits with project scope: `feat(01-toolkit): add backup script`.
4. Pull Request with `Closes #N`, squash merge.
5. Each project folder is self-contained: its own README, Makefile, tests and CI workflow.
