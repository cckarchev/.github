#!/usr/bin/env bash
# Applies the settings every CCK repository shares. Safe to run again: each
# step sets a value rather than adding to it, so it also brings a repository
# back in line after a change by hand.
#
# Usage: scripts/applyRepoSettings.sh <repo>
# Needs the gh CLI, signed in with admin rights on the repository.
#
# Description comes from the repository's package.json, or from the table
# below for a repository without one. Homepage and topics come from tables
# too; add a line there for a new repository. The ruleset requires the CI
# check only where the repository has a CI workflow to report it.
# Auto-merge, the main branch ruleset and private vulnerability reporting are
# only applied to public repositories: GitHub Free does not offer them on
# private ones.
set -euo pipefail

ORG="cckarchev"

# The check the main branch ruleset requires: the caller's `ci` job running
# the reusable `verify` job.
REQUIRED_CHECK="ci / verify"

RULESET_NAME="main"

# GitHub's built-in id for the repository admin role, the actor the ruleset
# lets bypass it.
ADMIN_ROLE_ID=5

CI_WORKFLOW=".github/workflows/ci.yml"

description_for() {
  case "$1" in
    .github) echo "Organization-wide files for the Centro Cultural Karchev repositories." ;;
    *) echo "" ;;
  esac
}

homepage_for() {
  case "$1" in
    cck-shared | .github) echo "" ;;
    cckarchev-web) echo "https://www.cckarchev.ar" ;;
    gb-parametric-tokens) echo "https://gb-tokens.cckarchev.ar" ;;
    *) echo "https://$1.cckarchev.ar" ;;
  esac
}

topics_for() {
  case "$1" in
    cck-shared) echo '["biome", "design-tokens", "typescript"]' ;;
    cckarchev-web) echo '["astro", "preact", "cloudflare-workers", "wargaming", "board-games"]' ;;
    gb-parametric-tokens) echo '["guild-ball", "react", "cloudflare-workers"]' ;;
    gb-meat-grinder) echo '["guild-ball", "react", "cloudflare-workers"]' ;;
    mw-spellbook-builder) echo '["mage-wars", "react", "cloudflare-workers"]' ;;
    wmr-list-builder) echo '["warmaster", "react", "cloudflare-workers"]' ;;
    *) echo '[]' ;;
  esac
}

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <repo>" >&2
  exit 1
fi

repo="$1"
full="$ORG/$repo"

visibility=$(gh repo view "$full" --json visibility --jq .visibility)

has_file() {
  gh api "repos/$full/contents/$1" --silent 2>/dev/null
}

if has_file package.json; then
  description=$(gh api "repos/$full/contents/package.json" \
    -H "Accept: application/vnd.github.raw+json" \
    --jq '.description // ""')
else
  description=$(description_for "$repo")
fi

echo "Settings for $full ($visibility)"

gh repo edit "$full" \
  --description "$description" \
  --homepage "$(homepage_for "$repo")" \
  --enable-issues \
  --enable-wiki=false \
  --enable-projects=false \
  --enable-discussions=false \
  --enable-squash-merge \
  --enable-merge-commit=false \
  --enable-rebase-merge=false \
  --delete-branch-on-merge \
  --allow-update-branch

# Squash commits take the pull request title and leave the body blank.
gh api -X PATCH "repos/$full" --silent \
  -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=BLANK

echo "{\"names\": $(topics_for "$repo")}" |
  gh api -X PUT "repos/$full/topics" --silent --input -

# The label the data error issue template applies.
gh label create data --repo "$full" --force \
  --color "d4c5f9" \
  --description "Wrong card, unit, stat or rule"

if [[ "$visibility" != "PUBLIC" ]]; then
  echo "Private: skipping auto-merge, ruleset and vulnerability reporting."
  exit 0
fi

# Through the REST API: `gh repo edit --enable-auto-merge` reports success
# without changing the setting.
gh api -X PATCH "repos/$full" --silent -F allow_auto_merge=true

gh api -X PUT "repos/$full/private-vulnerability-reporting" --silent

# The main branch takes changes only through a pull request that passes CI,
# with no approvals needed so a maintainer can merge their own. No force
# pushes and no deleting the branch. Admins bypass it, so a small change can
# go straight to main; everyone else, Dependabot included, goes through CI.
status_checks_rule=""

if has_file "$CI_WORKFLOW"; then
  status_checks_rule=$(
    cat <<EOF
,
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [{ "context": "$REQUIRED_CHECK" }]
      }
    }
EOF
  )
else
  echo "No $CI_WORKFLOW: the ruleset does not require a CI check."
fi

ruleset=$(
  cat <<EOF
{
  "name": "$RULESET_NAME",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [
    {
      "actor_id": $ADMIN_ROLE_ID,
      "actor_type": "RepositoryRole",
      "bypass_mode": "always"
    }
  ],
  "conditions": {
    "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["squash"]
      }
    }$status_checks_rule
  ]
}
EOF
)

ruleset_id=$(gh api "repos/$full/rulesets" \
  --jq ".[] | select(.name == \"$RULESET_NAME\") | .id")

if [[ -n "$ruleset_id" ]]; then
  echo "$ruleset" |
    gh api -X PUT "repos/$full/rulesets/$ruleset_id" --silent --input -
else
  echo "$ruleset" |
    gh api -X POST "repos/$full/rulesets" --silent --input -
fi

echo "Done."
