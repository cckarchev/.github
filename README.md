# .github

Organization-wide files for the Centro Cultural Karchev repositories.

- `profile/README.md`: the organization's public profile page.
- `CONTRIBUTING.md`, `SECURITY.md`, `pull_request_template.md` and
  `ISSUE_TEMPLATE/`: the default community files. GitHub shows them in every
  repository that has none of its own.
- `.github/workflows/`: reusable workflows the projects call.
- `scripts/applyRepoSettings.sh`: the repository settings every project shares.

## Reusable workflows

`verify.yml` installs from the lockfile and runs the project's
`npm run verify` on the Node version in its `.node-version`. A project calls it
from `.github/workflows/ci.yml`, keeping the job id `ci` because the main
branch ruleset requires the `ci / verify` check:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    uses: cckarchev/.github/.github/workflows/verify.yml@main
```

`dependabot-auto-merge.yml` queues patch and minor Dependabot updates to
squash merge once CI passes, and leaves majors for review. It needs auto-merge
and the ruleset, so only public repositories use it:

```yaml
name: Dependabot auto-merge

on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    uses: cckarchev/.github/.github/workflows/dependabot-auto-merge.yml@main
```

## Repository settings

```sh
scripts/applyRepoSettings.sh <repo>
```

Sets the description (from `package.json`), homepage, topics, squash-only
merges titled after the pull request, branch deletion on merge, and turns off
the wiki, projects and discussions. On public repositories it also enables
auto-merge, private vulnerability reporting, and a ruleset on `main` that
requires a pull request and the CI check, with no approvals, force pushes or
deletion. Run it after adding a repository, with a line for it in the
script's homepage and topics tables.
