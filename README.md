# Assignment 3 — CI/CD with GitHub Actions

This project demonstrates a local Bash application with automated linting, tests, and Docker build/smoke tests. GitHub Actions runs the same stages on pushes and pull requests. There is no cloud deployment.

## Project structure

```text
assignment-3/
├── README.md
├── app/app.sh
├── scripts/lint.sh
├── scripts/build.sh
├── tests/test.sh
├── .github/workflows/ci.yml
├── Dockerfile
├── compose.yaml
├── .dockerignore
└── grade.sh
```

## Prerequisites

- Bash on Linux/WSL
- Git
- Docker Engine/Desktop with Linux containers enabled
- GitHub repository with Actions enabled

## Application usage

```bash
chmod +x grade.sh app/*.sh scripts/*.sh tests/*.sh
./app/app.sh help
./app/app.sh system-info
./app/app.sh check-host example.com
./app/app.sh check-port example.com 443
```

Exit codes:
- `0` success
- `1` operational failure
- `2` invalid command/input

`check-host` resolves the hostname and attempts an ICMP ping if available. ICMP may be blocked by firewalls, so DNS resolution is reported independently. `check-port` validates the port and attempts a TCP connection.

## Local validation and tests

```bash
./scripts/lint.sh
./tests/test.sh
./scripts/build.sh
./grade.sh
```

`lint.sh` checks required files and runs `bash -n` on the Bash scripts. `tests/test.sh` includes at least eight behaviour tests. `build.sh` builds the Docker image and performs smoke tests, including an invalid-command test.

## Docker

```bash
docker build -t devops-tool .
docker run --rm devops-tool help
docker run --rm devops-tool system-info
docker compose run --rm app help
```

## GitHub Actions pipeline

Workflow file: `.github/workflows/ci.yml`.

- **validate** runs linting.
- **test** runs after `validate` succeeds.
- **docker** runs after `test` succeeds and builds/smoke-tests the image.
- The workflow triggers on `push` and `pull_request`.
- `needs:` establishes the order between jobs.

GitHub-hosted Ubuntu runners provide Docker and Bash for these jobs.

## Demonstrating a CI failure and recovery

After pushing the working project to GitHub:

1. Create and push a temporary branch, for example `ci/demo-failure`.
2. Introduce a deliberate, temporary Bash syntax error in `app/app.sh` (for example, remove a closing `fi`), then commit and push it.
3. Open the repository's **Actions** tab and verify the workflow fails in the `validate` job.
4. Restore the correct script, commit the fix, and push again.
5. Verify the new workflow run passes. Merge the corrected branch through a pull request if using that workflow.

Example Git commands:

```bash
git switch -c ci/demo-failure
# Make a temporary syntax error in app/app.sh, save the file:
git add app/app.sh
git commit -m "test: demonstrate CI lint failure"
git push -u origin ci/demo-failure
# After observing the failed workflow, repair app/app.sh:
git add app/app.sh
git commit -m "fix: restore valid Bash syntax"
git push
```

Do not leave the syntax error in the final branch. In the final README, record the actual failed and successful workflow runs/commit IDs once you have observed them. Do not claim a CI failure demonstration happened unless you performed it.

## Assumptions and limitations

- The pipeline validates, tests and builds a Docker image; it does not publish the image or deploy it.
- Tests that contact external hosts may be affected by network restrictions. The included tests use localhost for port validation and `example.com` for DNS, so DNS availability is needed for that test.
- Docker tests require a functioning Docker daemon locally; GitHub-hosted runners provide Docker for the workflow.
