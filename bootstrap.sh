#!/usr/bin/env bash
# Adds the standard workflows to a repo and switches on the repo settings that go with them.
#
#   cd my-new-project
#   curl -fsSL https://raw.githubusercontent.com/Wickedsoni/.github/main/bootstrap.sh | bash -s -- android
#
# Kinds: android | kobweb | node. Existing files are never overwritten.
# Pass --no-settings to only copy files. Settings need the GitHub CLI (`gh`) logged in.
set -euo pipefail

kind="${1:-}"
settings=true
[ "${2:-}" = "--no-settings" ] && settings=false
case "$kind" in android|kobweb|node) ;; *) echo "usage: bootstrap.sh <android|kobweb|node> [--no-settings]" >&2; exit 1 ;; esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL https://codeload.github.com/Wickedsoni/.github/tar.gz/main | tar -xz -C "$tmp"
src="$tmp/.github-main/starters"

copy() {
  (cd "$1" && find . -type f) | while read -r f; do
    if [ -e "$f" ]; then echo "  keep   $f (already exists)"
    else mkdir -p "$(dirname "$f")"; cp "$1/$f" "$f"; echo "  add    $f"; fi
  done
}
echo "Adding $kind workflows:"
copy "$src/common"
copy "$src/$kind"

if $settings && command -v gh >/dev/null && repo="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)"; then
  echo "Configuring $repo:"
  gh api -X PATCH "repos/$repo" -F delete_branch_on_merge=true -F allow_auto_merge=true \
    -F allow_squash_merge=true -F squash_merge_commit_title=PR_TITLE -F squash_merge_commit_message=PR_BODY >/dev/null \
    && echo "  merge settings: squash with PR title, auto-merge on, delete branch after merge"
  gh api -X PUT "repos/$repo/vulnerability-alerts" >/dev/null 2>&1 && echo "  Dependabot alerts on"
  gh api -X PUT "repos/$repo/automated-security-fixes" >/dev/null 2>&1 && echo "  Dependabot security fixes on"
  gh api -X PUT "repos/$repo/private-vulnerability-reporting" >/dev/null 2>&1 && echo "  private vulnerability reporting on"
else
  echo "Skipped repo settings (no gh, no GitHub remote, or --no-settings)."
fi

cat <<EOF

Done. Next:
  - commit the new .github/ files and push
  - name PRs like "feat: ..." or "fix: ..." so release notes group them
EOF
case "$kind" in
  android) echo "  - for signed releases add secrets ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD" ;;
  kobweb)  echo "  - add secrets VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID and check site-dir in .github/workflows/deploy.yml" ;;
esac
