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
chmod +x backup_github.sh clone_all_repos.sh
```

## Automated Scheduling

Set up daily automated backups using macOS launchd by creating a launch agent:

1. **Create a launch agent plist file** at `~/Library/LaunchAgents/com.github.backup.daily.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.github.backup.daily</string>
    <key>Program</key>
    <string>/path/to/your/backup_github.sh</string>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>11</integer>
        <key>Minute</key>
        <integer>40</integer>
    </dict>
    <key>WorkingDirectory</key>
    <string>/path/to/your/script/directory</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>HOME</key>
        <string>/Users/yourusername</string>
    </dict>
</dict>
</plist>
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

# Check job status
launchctl list | grep github
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

Scripts provide detailed output and progress tracking:

- **Console output**: Real-time progress indicators and status updates
- **launchd logs**: When using automated scheduling, logs are captured in system logs
- **Error reporting**: Clear error messages for troubleshooting

**View launchd logs:**
```bash
# Check system logs for your backup job
log show --predicate 'subsystem == "com.apple.launchd"' --info --last 1h | grep github

# Or check Console.app for detailed system logging
```

## Troubleshooting

### Common Issues

1. **Permission denied errors**: Ensure scripts have execute permissions (`chmod +x *.sh`)
2. **Command not found**: Check PATH in environment variables or install missing tools
3. **Authentication failures**: Run `gh auth login` and grant repo scope
4. **launchd issues**: Check Console.app or system logs for error details

### Debugging

```bash
# Test GitHub CLI authentication
gh auth status

# Check available commands
which gh git jq

# Test script manually
./backup_github.sh

# Check system logs for launchd issues
log show --predicate 'subsystem == "com.apple.launchd"' --info --last 1h | grep github
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