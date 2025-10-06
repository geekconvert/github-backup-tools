# GitHub Backup Tools

Automated GitHub repository backup and cloning tools with scheduling support for macOS.

## Features

- **Complete Repository Backup**: Mirror clones with all branches, tags, and references
- **Working Copy Cloning**: Normal clones for development work
- **Automated Scheduling**: Daily backups using macOS launchd
- **Organization Support**: Backup repos from multiple GitHub organizations
- **Filtering Options**: Include/exclude forks and archived repositories
- **Wiki Backup**: Optional wiki repository backup
- **Git LFS Support**: Large File Storage object backup
- **Progress Tracking**: Detailed logging and progress indicators

## Scripts

### `backup_github.sh`
Creates mirror backups of all your GitHub repositories.

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

### `daily_backup.sh`
Wrapper script for automated daily backups with logging and cleanup.

**Features:**
- Timestamped logging
- Environment setup
- Automatic cleanup of old backups
- Error handling and notifications

**Usage:**
```bash
./daily_backup.sh
```

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
```

### Make Scripts Executable

```bash
chmod +x backup_github.sh clone_all_repos.sh daily_backup.sh
```

## Automated Scheduling

Set up daily automated backups at 11:40 AM using macOS launchd:

1. **Copy the launch agent configuration:**
```bash
cp com.github.backup.daily.plist ~/Library/LaunchAgents/
```

2. **Load the launch agent:**
```bash
launchctl load ~/Library/LaunchAgents/com.github.backup.daily.plist
```

3. **Verify it's loaded:**
```bash
launchctl list | grep github
```

### Manual Testing

Test the scheduled job manually:
```bash
launchctl start com.github.backup.daily
```

### Management Commands

```bash
# Stop scheduled backups
launchctl unload ~/Library/LaunchAgents/com.github.backup.daily.plist

# Restart scheduled backups
launchctl load ~/Library/LaunchAgents/com.github.backup.daily.plist

# View logs
tail -f logs/backup_*.log
```

## Output Structure

### Mirror Backups (`backup_github.sh`)
```
github-backup-YYYYMMDD_HHMMSS/
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

## Logging

All scripts provide detailed logging:

- **Backup logs**: `logs/backup_YYYYMMDD_HHMMSS.log`
- **launchd logs**: `logs/launchd_stdout.log`, `logs/launchd_stderr.log`
- **Progress indicators**: Real-time status updates

## Troubleshooting

### Common Issues

1. **Permission denied errors**: Ensure scripts have execute permissions
2. **Command not found**: Check PATH in environment variables
3. **Authentication failures**: Run `gh auth login` and grant repo scope
4. **launchd issues**: Check logs in `logs/` directory

### Debugging

```bash
# Test GitHub CLI authentication
gh auth status

# Check available commands
which gh git jq

# Test script manually
./backup_github.sh

# View recent logs
ls -la logs/
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