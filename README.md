# terminalenv

Personal terminal environment — dotfiles, shell utilities, and tmux config — installable on any machine with a single command.

## Install

```bash
curl -sL https://raw.githubusercontent.com/rgeary1/terminalenv/refs/heads/master/install.sh | bash
```

This downloads everything to `~/.dotfiles/`, then copies files into place under `$HOME`.

## What's Included

**Shell config:** `.bashrc.local`, `.zshrc`, `.shell_alias`, `.git_alias`, `.inputrc`, `.vimrc`, `.gdbinit`, `.lessfilter`

**Tmux:** `.tmux.conf` with `Ctrl-G` prefix, tmux plugin manager (tpm) auto-installed

**Utilities (`~/bin/`):**

| Script | Purpose |
|---|---|
| `gc`, `gl`, `gd`, `ga`, `gcm` | Git shortcuts (commit, log, diff, add, commit-message) |
| `git-uncommit` | Undo last commit |
| `findf`, `find-root` | File/project root finding |
| `xcat`, `xgrep` | Extended cat/grep with highlighting |
| `colorpath`, `field` | Text processing helpers |
| `tmux-a`, `tmux-restore-pane` | Tmux attach and pane restore |
| `terminal-rename`, `synctime` | Terminal title and clock sync |
| `awsdev`, `aws_sleep_on_idle` | AWS EC2 helpers |
| `backup_snapshot.sh` | Backup utility |
| `jq` | JSON processor |

**Packages:** Installs [mosh](https://mosh.org/) from source if not present.

## Update

Re-run the install command, or:

```bash
bash ~/.dotfiles/update.sh
```

## Development

```bash
# Compare your live dotfiles against this repo
./diff.sh

# Copy live changes back into the repo
./diff.sh -u
```

To add a new file, place it under `dotfiles/` and add its path to `dotfiles/filelist`.

## License

MIT
