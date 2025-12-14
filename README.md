Under these unprecendeted times, noone knows when which service will get blocked in your country so keep a backup of all repos at your working system or any vps using this repo.

# GitHub Backup Tools

Automated GitHub repository backup and cloning tools with scheduling support for macOS.

## Scripts

### `backup_github.sh`
Creates mirror backups of all your GitHub repositories. Subsequent runs update the same backup directory so only new refs are transferred.

**Features:**
- Mirror clones (preserves all refs)
- Wiki backup support
- Git LFS object backup
- SSH/HTTPS protocol selection
- Incremental updates

**Usage:**
```bash
./backup_github.sh
```

### `clone_all_repos.sh`
Creates working copies of all your GitHub repositories for development.

**Features:**
- Normal git clones
- Working directory setup
- Smart update handling
- Branch and commit information

**Usage:**
```bash
./clone_all_repos.sh
```

## Features

- **Complete Repository Backup**: Mirror clones with all branches, tags, and references
- **Working Copy Cloning**: Normal clones for development work
- **Automated Scheduling**: Daily backups using macOS launchd
- **Organization Support**: Backup repos from multiple GitHub organizations
- **Filtering Options**: Include/exclude forks and archived repositories
- **Wiki Backup**: Optional wiki repository backup
- **Git LFS Support**: Large File Storage object backup
- **Progress Tracking**: Detailed logging and progress indicators


## Setup

### Prerequisites

- macOS
- [GitHub CLI](https://cli.github.com/) (`gh`)
- Git
- jq (JSON processor)
- Git LFS (optional, for LFS support)

```bash
# Install prerequisites with Homebrew
brew install gh git jq git-lfs
```

### Authentication

```bash
# Login to GitHub CLI
gh auth login
```

### Configuration

Edit the configuration section in each script:

```bash
# Organizations to include (optional)
declare -a ORG_LIST=(myorg anotherorg)

# What to include
INCLUDE_FORKS=false
INCLUDE_ARCHIVED=false
INCLUDE_WIKIS=true
INCLUDE_LFS=true

# Protocol selection
CLONE_PROTOCOL=ssh   # ssh|https

# Optional override for backup location
BACKUP_DIR_OVERRIDE="/path/to/existing/backup"
```

### Make Scripts Executable

```bash
chmod +x backup_github.sh clone_all_repos.sh
```

## Automated Scheduling

Based on your systems you can schedule this daily at sometime in your system.

## Output Structure

### Mirror Backups (`backup_github.sh`)
```
github-backup/
├── username/
│   ├── repo1.git/          # Mirror clone
│   ├── repo1.wiki.git/     # Wiki backup
│   ├── repo2.git/
│   └── ...
└── organization/
    ├── org-repo1.git/
    └── ...
```

### Working Copies (`clone_all_repos.sh`)
```
github-repos-YYYYMMDD_HHMMSS/
├── username/
│   ├── repo1/              # Working directory
│   ├── repo2/
│   └── ...
└── organization/
    ├── org-repo1/
    └── ...
```

## License

MIT License - feel free to use and modify as needed.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Author

Created for automated GitHub repository management and backup workflows.
