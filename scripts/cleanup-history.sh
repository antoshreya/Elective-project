#!/usr/bin/env bash
set -euo pipefail

# Path of the large file (relative to repo root)
TARGET="terraform/.terraform/providers/registry.terraform.io/hashicorp/aws/6.16.0/windows_386/terraform-provider-aws_v6.16.0_x5.exe"

echo "==> Removing $TARGET from git history (local only). Read script before running."

# 1) Make sure .terraform is ignored
if ! grep -qF ".terraform" .gitignore 2>/dev/null; then
  echo -e "\n# Ignore any terraform working directories\n**/.terraform/\n.terraform.lock.hcl" >> .gitignore
  git add .gitignore
  git commit -m "chore: add .terraform to .gitignore" || true
fi

# 2) Unstage any tracked .terraform now (best-effort)
git rm --cached -r terraform/.terraform || true
git commit -m "chore: remove tracked .terraform from index" || true

# 3) Use git-filter-repo if available (recommended)
if command -v git-filter-repo >/dev/null 2>&1; then
  echo "Using git-filter-repo to remove path from history..."
  git filter-repo --invert-paths --paths "$TARGET"
else
  echo "git-filter-repo not found."
  if command -v bfg >/dev/null 2>&1; then
    echo "Using BFG to remove file by name (requires java + bfg)."
    FNAME=$(basename "$TARGET")
    # create a temporary bare clone for BFG safety
    git clone --mirror . repo-mirror.git
    pushd repo-mirror.git >/dev/null
    bfg --delete-files "$FNAME"
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
    popd >/dev/null
    # replace current repo with cleaned mirror
    rm -rf .git
    mv repo-mirror.git .git
    git reset --hard
  else
    echo "Neither git-filter-repo nor bfg found. Install git-filter-repo (recommended) or BFG and re-run this script."
    exit 1
  fi
fi

# 4) Final cleanup and force push
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "About to force-push cleaned history to origin/main. This rewrites remote history."
read -p "Type 'yes' to proceed with force-push: " CONFIRM
if [ "$CONFIRM" = "yes" ]; then
  git push origin main --force
  echo "Force-pushed cleaned history."
else
  echo "Aborted. No changes pushed."
fi

echo "Done. Locally run 'terraform init' inside terraform/ to recreate .terraform (do NOT commit it)."
