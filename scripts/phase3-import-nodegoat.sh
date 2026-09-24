#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Phase 3 - Import OWASP NodeGoat and preserve baseline
#
# This script:
#   1. Verifies current Git repository
#   2. Requires a clean working tree
#   3. Creates Phase 3 directory structure
#   4. Temporarily clones official OWASP NodeGoat
#   5. Records upstream commit metadata
#   6. Imports NodeGoat WITHOUT its .git directory
#   7. Verifies imported source against upstream
#   8. Creates UPSTREAM_BASELINE.md
#   9. Creates nodegoat-upstream.env
#
# It DOES NOT:
#   - modify NodeGoat source code
#   - commit automatically
#   - push automatically
#   - create the vulnerable-baseline tag automatically
# ============================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_REPO="https://github.com/OWASP/NodeGoat.git"
UPSTREAM_TMP="/tmp/NodeGoat-upstream"

echo
echo "============================================================"
echo " PHASE 3 - OWASP NodeGoat Baseline Import"
echo "============================================================"
echo

cd "$PROJECT_ROOT"

echo "[1/11] Checking project repository..."

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: $PROJECT_ROOT is not inside a Git repository."
    exit 1
fi

echo "Project root:"
echo "$PROJECT_ROOT"
echo

# ------------------------------------------------------------
# Step 3.1 - Check repository state
# ------------------------------------------------------------

echo "[2/11] Checking Git working tree..."

if [[ -n "$(git status --porcelain)" ]]; then
    echo
    echo "ERROR: Git working tree is not clean."
    echo
    git status --short
    echo
    echo "Commit, stash, or remove these changes before running Phase 3."
    exit 1
fi

echo "Working tree is clean."
echo

echo "Current Git history:"
git log --oneline --decorate --graph --all -10 || true

echo

# ------------------------------------------------------------
# Step 3.2 - Create required directories
# ------------------------------------------------------------

echo "[3/11] Creating Phase 3 directories..."

mkdir -p app
mkdir -p docker/scripts
mkdir -p security/semgrep
mkdir -p security/gitleaks
mkdir -p security/trivy
mkdir -p security/zap
mkdir -p security/evidence
mkdir -p vault/config
mkdir -p vault/policies
mkdir -p vault/scripts
mkdir -p logs
mkdir -p .github/workflows
mkdir -p docs/project

echo "Directories created."
echo

# Protect against accidentally overwriting an existing application.
if [[ -n "$(find app -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    echo "ERROR: app/ is not empty."
    echo
    echo "For safety, this script will NOT overwrite an existing app/."
    echo "Inspect the directory manually:"
    echo
    echo "    ls -la app"
    echo
    exit 1
fi

# ------------------------------------------------------------
# Steps 3.3 - 3.4 - Clone upstream and record metadata
# ------------------------------------------------------------

echo "[4/11] Preparing temporary upstream clone..."

rm -rf "$UPSTREAM_TMP"

echo "Cloning:"
echo "$UPSTREAM_REPO"
echo

git clone "$UPSTREAM_REPO" "$UPSTREAM_TMP"

echo
echo "Upstream remote:"
git -C "$UPSTREAM_TMP" remote -v

echo

UPSTREAM_SHA="$(git -C "$UPSTREAM_TMP" rev-parse HEAD)"
UPSTREAM_SHORT_SHA="$(git -C "$UPSTREAM_TMP" rev-parse --short HEAD)"
UPSTREAM_DATE="$(git -C "$UPSTREAM_TMP" show -s --format='%cI' HEAD)"
UPSTREAM_MESSAGE="$(git -C "$UPSTREAM_TMP" show -s --format='%s' HEAD)"
UPSTREAM_BRANCH="$(git -C "$UPSTREAM_TMP" branch --show-current)"

echo "[5/11] Upstream metadata collected."
echo
echo "Repository : $UPSTREAM_REPO"
echo "Branch     : $UPSTREAM_BRANCH"
echo "Commit     : $UPSTREAM_SHA"
echo "Short SHA  : $UPSTREAM_SHORT_SHA"
echo "Date       : $UPSTREAM_DATE"
echo "Message    : $UPSTREAM_MESSAGE"
echo

# ------------------------------------------------------------
# Steps 3.5 - 3.6 - Inspect repository and license
# ------------------------------------------------------------

echo "[6/11] Checking important upstream files..."

REQUIRED_FILES=(
    "Dockerfile"
    "docker-compose.yml"
    "package.json"
    "server.js"
    "LICENSE"
    "README.md"
)

for FILE in "${REQUIRED_FILES[@]}"; do
    if [[ -e "$UPSTREAM_TMP/$FILE" ]]; then
        printf "  [OK] %s\n" "$FILE"
    else
        printf "  [WARNING] %s not found\n" "$FILE"
    fi
done

echo

if [[ -f "$UPSTREAM_TMP/LICENSE" ]]; then
    echo "License preview:"
    head -20 "$UPSTREAM_TMP/LICENSE"
else
    echo "WARNING: LICENSE file was not found."
fi

echo

# ------------------------------------------------------------
# Step 3.8 - Import source without .git
# ------------------------------------------------------------

echo "[7/11] Importing NodeGoat into app/ WITHOUT upstream .git..."

git -C "$UPSTREAM_TMP" archive --format=tar HEAD \
    | tar -x -C "$PROJECT_ROOT/app"

echo "Import complete."
echo

echo "Checking for nested .git directories..."

NESTED_GIT="$(find "$PROJECT_ROOT/app" -name .git -type d -print || true)"

if [[ -n "$NESTED_GIT" ]]; then
    echo "ERROR: Nested .git directory detected:"
    echo "$NESTED_GIT"
    exit 1
fi

echo "No nested Git repository detected."
echo

# ------------------------------------------------------------
# Step 3.9 - Verify imported files
# ------------------------------------------------------------

echo "[8/11] Verifying imported source against upstream..."

DIFF_FILE="$(mktemp)"

if diff -qr \
    --exclude=.git \
    "$UPSTREAM_TMP" \
    "$PROJECT_ROOT/app" >"$DIFF_FILE"; then

    echo "Verification PASSED."
    echo "Imported app/ matches upstream NodeGoat source."

else
    echo
    echo "ERROR: Imported files differ from upstream."
    echo
    cat "$DIFF_FILE"
    rm -f "$DIFF_FILE"
    exit 1
fi

rm -f "$DIFF_FILE"

echo

# ------------------------------------------------------------
# Step 3.10 - Create documentation
# ------------------------------------------------------------

echo "[9/11] Creating docs/project/UPSTREAM_BASELINE.md..."

cat > "$PROJECT_ROOT/docs/project/UPSTREAM_BASELINE.md" <<EOF
# OWASP NodeGoat Upstream Baseline

## Source Project

OWASP NodeGoat

## Official Repository

https://github.com/OWASP/NodeGoat

## Purpose

NodeGoat is used as the intentionally vulnerable open-source
application for the IE3142 DevOps Security assignment.

## Import Strategy

The official repository is cloned temporarily and exported into:

\`\`\`text
app/
\`\`\`

The upstream \`.git\` directory is intentionally not copied.

This ensures that the entire university project uses one Git
repository while still preserving the exact original NodeGoat source.

## Upstream Commit

\`\`\`text
$UPSTREAM_SHA
\`\`\`

## Upstream Branch

\`\`\`text
$UPSTREAM_BRANCH
\`\`\`

## Upstream Commit Date

\`\`\`text
$UPSTREAM_DATE
\`\`\`

## Upstream Commit Message

\`\`\`text
$UPSTREAM_MESSAGE
\`\`\`

## License

Apache License 2.0

## Original Components

Primary components:

1. Node.js / Express web application
2. MongoDB database

## Original Docker Support

The upstream repository contains:

- Dockerfile
- docker-compose.yml

These files are initially preserved without modification.

## Baseline Rule

The imported NodeGoat application source must remain untouched until
the vulnerable baseline has been documented and tagged.

All future security modifications will be performed through dedicated
branches.

## Baseline Tag

The project will use:

\`\`\`text
vulnerable-baseline
\`\`\`

to identify the untouched NodeGoat baseline.

## Ethical Boundary

Security testing is limited to the authorised local project instance.

No third-party system will be tested.
EOF

echo "Created:"
echo "docs/project/UPSTREAM_BASELINE.md"
echo

# ------------------------------------------------------------
# Step 3.11 - Machine-readable upstream metadata
# ------------------------------------------------------------

echo "[10/11] Creating docs/project/nodegoat-upstream.env..."

cat > "$PROJECT_ROOT/docs/project/nodegoat-upstream.env" <<EOF
NODEGOAT_REPOSITORY=$UPSTREAM_REPO
NODEGOAT_BRANCH=$UPSTREAM_BRANCH
NODEGOAT_COMMIT=$UPSTREAM_SHA
NODEGOAT_COMMIT_DATE=$UPSTREAM_DATE
NODEGOAT_LICENSE=Apache-2.0
EOF

echo
cat "$PROJECT_ROOT/docs/project/nodegoat-upstream.env"

echo

# ------------------------------------------------------------
# Final validation
# ------------------------------------------------------------

echo "[11/11] Running final validation..."

echo
echo "Checking imported application:"
ls -la "$PROJECT_ROOT/app" | head -25

echo
echo "Checking nested Git repositories:"
if find "$PROJECT_ROOT/app" -name .git -type d | grep -q .; then
    echo "FAILED: Nested .git found."
    exit 1
else
    echo "PASS: No nested .git directory."
fi

echo
echo "Recorded upstream SHA:"
grep '^NODEGOAT_COMMIT=' \
    "$PROJECT_ROOT/docs/project/nodegoat-upstream.env"

echo
echo "Git status:"
git status --short

echo
echo "============================================================"
echo " PHASE 3 IMPORT SUCCESSFUL"
echo "============================================================"
echo
echo "Upstream:"
echo "  Repository : $UPSTREAM_REPO"
echo "  Branch     : $UPSTREAM_BRANCH"
echo "  Commit     : $UPSTREAM_SHA"
echo "  Short SHA  : $UPSTREAM_SHORT_SHA"
echo
echo "Imported to:"
echo "  $PROJECT_ROOT/app"
echo
echo "Documentation:"
echo "  docs/project/UPSTREAM_BASELINE.md"
echo "  docs/project/nodegoat-upstream.env"
echo
echo "IMPORTANT:"
echo "  NodeGoat source has NOT been modified."
echo "  Nothing has been committed automatically."
echo "  No Git tag has been created automatically."
echo
echo "Review the result using:"
echo
echo "  git status"
echo "  git diff --stat"
echo "  cat docs/project/nodegoat-upstream.env"
echo
echo "After verification, the baseline can be committed and tagged."
echo "============================================================"

