#!/usr/bin/env bash

# Clone all GitHub repos for your user (and optional organizations) as working directories.
# Creates normal git clones that you can work with, not mirror backups.
# Requires: bash, gh, git, jq

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
# Use SSH or HTTPS for cloning (SSH recommended if you have keys set up)
CLONE_PROTOCOL=ssh   # ssh|https

# Clone location
CLONE_DIR="${PWD}/github-repos-$(date +%Y%m%d_%H%M%S)"

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

# Ensure we're logged in (token with repo scope if you want private repos)
if ! gh auth status >/dev/null 2>&1; then
  echo "You must run: gh auth login   (grant at least 'repo' scope for private repos)" >&2
  exit 1
fi

mkdir -p "$CLONE_DIR"
echo "Cloning repositories to: $CLONE_DIR"

# Determine your username via gh
OWNER_USER="$(gh api user -q .login)"

# Build owners list safely
OWNERS=("$OWNER_USER")

# Check if ORG_LIST has any elements
ORG_COUNT=${#ORG_LIST[@]:-0}  # Get array length, default to 0 if unset
if [[ $ORG_COUNT -gt 0 ]]; then
  # Add all organizations to the OWNERS array
  for org in "${ORG_LIST[@]}"; do
    OWNERS+=("$org")
  done
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
#         CLONE FUNCTION            #
#####################################

clone_repo_working() {
  local full_name="$1" ssh_url="$2" https_url="$3" is_fork="$4" is_archived="$5"

  local owner="${full_name%/*}"
  local repo="${full_name#*/}"
  local dest="${CLONE_DIR}/${owner}"
  local repo_path="${dest}/${repo}"
  local url
  url="$(repo_clone_url "$ssh_url" "$https_url")"

  mkdir -p "$dest"

  # Clone or update the repo
  if [[ ! -d "$repo_path" ]]; then
    echo "→ Cloning ${full_name}"
    if git clone "$url" "$repo_path"; then
      echo "   ✅ Successfully cloned ${full_name}"
      
      # Set up some useful info
      cd "$repo_path"
      echo "   📁 Working directory: $repo_path"
      
      # Show current branch
      local current_branch
      current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
      echo "   🌳 Current branch: $current_branch"
      
      # Show last commit
      local last_commit
      last_commit=$(git log -1 --oneline 2>/dev/null || echo "No commits")
      echo "   📝 Last commit: $last_commit"
      
      cd - >/dev/null
    else
      echo "   ❌ Failed to clone ${full_name}"
    fi
  else
    echo "→ Updating ${full_name}"
    cd "$repo_path"
    
    # Fetch latest changes
    if git fetch origin; then
      # Get current branch
      local current_branch
      current_branch=$(git branch --show-current 2>/dev/null || echo "")
      
      if [[ -n "$current_branch" ]]; then
        # Try to fast-forward if on a branch
        if git merge --ff-only "origin/$current_branch" 2>/dev/null; then
          echo "   ✅ Updated to latest ${current_branch}"
        else
          echo "   ⚠️  Has local changes - fetch completed but not merged"
        fi
      else
        echo "   ℹ️  On detached HEAD - fetched latest changes"
      fi
      
      # Show last commit
      local last_commit
      last_commit=$(git log -1 --oneline 2>/dev/null || echo "No commits")
      echo "   📝 Last commit: $last_commit"
    else
      echo "   ❌ Failed to fetch updates for ${full_name}"
    fi
    
    cd - >/dev/null
  fi
  
  # Add separator line after processing each repository
  echo "----------------"
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
  # Determine if this is a user or organization
  if [[ "$owner" == "$OWNER_USER" ]]; then
    kind="user"
  else
    kind="org"
  fi
  echo "== Cloning ${kind} repos for: ${owner} =="

  # Get all repo data into an array first
  echo "  Fetching repository list..."
  
  # Read lines into array using a more compatible method
  repo_lines=()
  while IFS= read -r line; do
    repo_lines+=("$line")
  done < <(list_repos "$owner" "$kind" | jq -r \
    '[.full_name, .ssh_url, .clone_url, (.fork|tostring), (.archived|tostring)] | join("|")')
  
  echo "  Found ${#repo_lines[@]} repositories"
  
  # Process each repository
  for repo_line in "${repo_lines[@]}"; do
    # Split the pipe-delimited line into variables
    IFS='|' read -r full_name ssh_url https_url is_fork is_archived <<< "$repo_line"
    
    if filter_repo "$is_fork" "$is_archived"; then
      clone_repo_working "$full_name" "$ssh_url" "$https_url" "$is_fork" "$is_archived"
    else
      echo "Skipping ${full_name} (fork/archived filter)"
      echo "----------------"
    fi
  done
done

echo "✅ Done. All repositories are under: $CLONE_DIR"
echo ""
echo "📋 Quick navigation tips:"
echo "  cd $CLONE_DIR"
echo "  find . -name '*.git' -type d | head -10  # List first 10 repos"
echo "  find . -name 'README*' | head -10       # Find README files"
echo ""
echo "🔧 To work on a specific repo:"
echo "  cd $CLONE_DIR/$OWNER_USER/repository-name"
echo "  git status                               # Check repo status"
echo "  git branch -a                           # See all branches"