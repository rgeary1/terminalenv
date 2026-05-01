# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**terminalenv** is a personal terminal environment (dotfiles + utilities) that can be bootstrapped onto any machine via a single curl command. Files are individually fetched from GitHub raw URLs — no git clone required on the target.

## Architecture

**Three-stage remote install pipeline:**
1. `install.sh` (root) — entry point, fetches `dotfiles/update.sh` and runs it
2. `dotfiles/update.sh` — downloads tarball (preferred) or individual files from `dotfiles/filelist` to `~/.dotfiles/`, then runs `dotfiles/install.sh`
3. `dotfiles/install.sh` — copies files from `~/.dotfiles/` to `$HOME`, sets up `.bashrc` sourcing, installs mosh if missing, installs tmux plugin manager

**`dotfiles/filelist`** is the manifest of all deployed files. Any new dotfile or bin script must be added here to be installed. Note: filelist currently has duplicate entries — this is harmless but worth cleaning up.

**Tarball packaging:** `update.sh` tries to download `dotfiles.tar.gz` first for faster installs, falling back to individual file downloads. The tarball is stored in-repo and must be regenerated after changing dotfiles.

**Checksum tracking:** `install.sh` saves MD5 checksums of installed files to `~/.dotfiles/.installed_checksums`. On subsequent installs, it warns if deployed files were locally modified before overwriting.

## Key Commands

```bash
# Compare deployed dotfiles against repo
./diff.sh           # show diffs
./diff.sh -q        # quiet mode (just list differing files)
./diff.sh -u        # copy deployed files back into repo

# Package and publish tarball (run after changing dotfiles)
./package.sh        # create dotfiles.tar.gz
./upload.sh         # package + commit tarball + push

# Push to GitHub (uses dedicated SSH key)
SSH_AGENT='' SSH_AUTH_SOCK='' GIT_SSH_COMMAND='ssh -i ~/.ssh/rgeary1' git push
```

## Beads Issue Tracking

Uses `br` (beads_rust) for task tracking. Issues stored in `.beads/` (SQLite DB, exported to JSONL for git).

```bash
br ready                    # Show actionable work
br create --title="..." --type=task --priority=2
br update <id> --status=in_progress
br close <id>
br sync --flush-only        # Export DB to JSONL before committing
```

Priority: 0=critical, 1=high, 2=medium, 3=low, 4=backlog. Types: task, bug, feature, epic, chore, docs, question.

**Always run `br sync --flush-only` before committing** to keep JSONL export in sync.

## Session End Checklist

```bash
git status
git add <files>
br sync --flush-only
git commit -m "..."
git push  # using the SSH command above
```

## Important Conventions

- `$SRC_URL` controls the download source (defaults to GitHub raw master)
- `$DESTDIR` controls install target (defaults to `$HOME`)
- All bin/ scripts must be listed in `dotfiles/filelist` to be deployed
- After modifying dotfiles, run `./upload.sh` (or `./package.sh` + commit) to update the tarball
- Shell support: bash and zsh (`.bashrc.local` and `.zshrc.local`)
- Tmux prefix is `Ctrl-G` (not default `Ctrl-B`)
