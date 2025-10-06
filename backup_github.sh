#!/usr/bin/env bash
# github-backup.sh
# Mirror-clone all GitHub repos for your user (and optional organizations).
# Preserves all refs (branches, tags). Optionally backs up wikis and Git LFS.
# Requires: bash, gh, git, jq  (git-lfs optional)

set -Eeuo pipefail

#####################################
#             CONFIG                #
#####################################

# Organizations to include (optional). Leave empty for none.
# Example: declare -a ORG_LIST=(myorg anotherorg)
declare -a ORG_LIST=()

# What to include
INCLUDE_FORKS=false
INCLUDE_ARCHIVED=false
INCLUDE_WIKIS=true
INCLUDE_LFS=true

# Use SSH or HTTPS for cloning (SSH recommended if you have keys set up)
CLONE_PROTOCOL=ssh   # ssh|https

# Backup location
BACKUP_DIR="${PWD}/github-backup-$(date +%Y%m%d_%H%M%S)"

#####################################
#        UTIL / DEP CHECKS          #
#####################################

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

need_cmd bash
need_cmd gh
need_cmd git
need_cmd jq

if [[ "${INCLUDE_LFS}" == "true" ]] && ! command -v git-lfs >/dev/null 2>&1; then
  echo "Note: git-lfs not found. LFS objects won't be fetched (set INCLUDE_LFS=false or install git-lfs)." >&2
fi

# Ensure we're logged in (token with repo scope if you want private repos)
if ! gh auth status >/dev/null 2>&1; then
  echo "You must run: gh auth login   (grant at least 'repo' scope for private repos)" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
echo "Backing up to: $BACKUP_DIR"

# Determine your username via gh
OWNER_USER="$(gh api user -q .login)"

# Build owners list safely
OWNERS=("$OWNER_USER")
if [[ ${#ORG_LIST[@]:-0} -gt 0 ]]; then
  OWNERS+=("${ORG_LIST[@]}")
fi

#####################################
#        GITHUB API HELPERS         #
#####################################

# List repos for a given owner.
# For user: we fetch /user/repos (all visible) and filter to owner login.
list_repos() {
  local owner="$1"
  local kind="$2" # user|org

  if [[ "$kind" == "user" ]]; then
    gh api -H "Accept: application/vnd.github+json" \
      /user/repos?per_page=100 --paginate \
      -q "map(select(.owner.login==\"${owner}\")) | .[]"
  else
    gh api -H "Accept: application/vnd.github+json" \
      "/orgs/${owner}/repos?per_page=100&type=all" --paginate \
      -q ".[]"
  fi
}

# Choose clone URL based on protocol
repo_clone_url() {
  local ssh_url="$1" https_url="$2"
  if [[ "$CLONE_PROTOCOL" == "https" ]]; then
    printf "%s" "$https_url"
  else
    printf "%s" "$ssh_url"
  fi
}

#####################################
#         MIRROR + EXTRAS           #
#####################################

clone_repo_mirror() {
  local full_name="$1" ssh_url="$2" https_url="$3" has_wiki="$4" is_fork="$5"

  local owner="${full_name%/*}"
  local repo="${full_name#*/}"
  local dest="${BACKUP_DIR}/${owner}"
  local url
  url="$(repo_clone_url "$ssh_url" "$https_url")"

  mkdir -p "$dest"

  # Mirror the main repo
  if [[ ! -d "${dest}/${repo}.git" ]]; then
    echo "→ Cloning ${full_name}"
    git clone --mirror --no-hardlinks "$url" "${dest}/${repo}.git"
  else
    echo "→ Updating ${full_name}"
    git --git-dir="${dest}/${repo}.git" remote update --prune
  fi

  # LFS (works on bare by using GIT_DIR)
  if [[ "$INCLUDE_LFS" == "true" ]] && command -v git-lfs >/dev/null 2>&1; then
    echo "   LFS: fetching all objects for ${full_name}"
    GIT_DIR="${dest}/${repo}.git" git lfs fetch --all || true
  fi

  # Wiki backup (only if not a fork; probe actual existence to avoid errors)
  if [[ "$INCLUDE_WIKIS" == "true" && "$is_fork" == "false" ]]; then
    # Re-check has_wiki from API (authoritative, cheap)
    if gh api "/repos/${owner}/${repo}" -q .has_wiki | grep -q true; then
      local wiki_dest="${dest}/${repo}.wiki.git"
      local wiki_url_ssh="git@github.com:${owner}/${repo}.wiki.git"
      local wiki_url_https="https://github.com/${owner}/${repo}.wiki.git"
      local wiki_url
      wiki_url="$(repo_clone_url "$wiki_url_ssh" "$wiki_url_https")"

      # Probe whether the wiki repo is reachable
      if git ls-remote "$wiki_url" >/dev/null 2>&1; then
        if [[ ! -d "$wiki_dest" ]]; then
          echo "   Wiki: cloning ${full_name}.wiki"
          git clone --mirror --no-hardlinks "$wiki_url" "$wiki_dest" >/dev/null 2>&1 || true
        else
          echo "   Wiki: updating ${full_name}.wiki"
          git --git-dir="$wiki_dest" remote update --prune >/dev/null 2>&1 || true
        fi
      else
        echo "   Wiki: not found or disabled (skipping)."
      fi
    fi
  fi
}

# Filter fork/archived per flags
filter_repo() {
  local is_fork="$1" is_archived="$2"
  if [[ "$INCLUDE_FORKS" == "false" && "$is_fork" == "true" ]]; then
    return 1
  fi
  if [[ "$INCLUDE_ARCHIVED" == "false" && "$is_archived" == "true" ]]; then
    return 1
  fi
  return 0
}

#####################################
#              RUN                  #
#####################################

for owner in "${OWNERS[@]}"; do
  kind="user"
  [[ "$owner" != "$OWNER_USER" ]] && kind="org"
  echo "== Enumerating ${kind} repos for: ${owner} =="

  # Emit: full_name|ssh_url|clone_url|has_wiki|fork|archived
  list_repos "$owner" "$kind" | jq -r \
    '[.full_name, .ssh_url, .clone_url, (.has_wiki|tostring), (.fork|tostring), (.archived|tostring)] | join("|")' |
  while IFS='|' read -r full_name ssh_url https_url has_wiki is_fork is_archived; do
    if filter_repo "$is_fork" "$is_archived"; then
      clone_repo_mirror "$full_name" "$ssh_url" "$https_url" "$has_wiki" "$is_fork"
    else
      echo "Skipping ${full_name} (fork/archived filter)"
    fi
  done
done

echo "✅ Done. All mirrored repos are under: $BACKUP_DIR"
echo "Tip: tar it up →  tar -czf ${BACKUP_DIR##*/}.tar.gz -C \"$(dirname "$BACKUP_DIR")\" \"${BACKUP_DIR##*/}\""
