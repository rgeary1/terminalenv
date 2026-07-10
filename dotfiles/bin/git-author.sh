# AI coding-tool git authorship tagging.
#
# Sourced from ~/.bashrc *above* the `case $- in *i*) ... return` interactive
# guard, so it also loads in non-interactive `bash -c` shells — the ones Claude
# Code / Cursor spawn for tool calls, and the login-but-non-interactive shell
# Claude Code snapshots at session start. It used to live in ~/.bashrc.local
# (below the guard), so tool-shell commits were authored untagged.

# In a Claude Code tool shell, tag git author as "<user.name> | <model>[, <effort>]".
# The live model is read from this session's transcript; the prefix comes from git config.
setClaudeGitAuthor() {
    [ -n "$CLAUDE_CODE_CHILD_SESSION" ] && [ -n "$CLAUDE_CODE_SESSION_ID" ] || return
    local transcript model_id model_name base tag
    transcript=$(find "$HOME/.claude/projects" -name "$CLAUDE_CODE_SESSION_ID.jsonl" 2>/dev/null | head -1)
    [ -n "$transcript" ] || return
    model_id=$(grep -oE '"model":"[^"]*"' "$transcript" | tail -1 | cut -d'"' -f4)
    case "$model_id" in
        claude-opus-4-8*)  model_name="Claude Opus 4.8" ;;
        claude-sonnet-5*)  model_name="Claude Sonnet 5" ;;
        claude-haiku-4-5*) model_name="Claude Haiku 4.5" ;;
        claude-fable-5*)   model_name="Claude Fable 5" ;;
        "")                return ;;
        *)                 model_name="$model_id" ;;  # unknown id: raw id, no guess
    esac
    base=$(command git config user.name 2>/dev/null)
    [ -n "$base" ] || return
    tag="$model_name"
    [ -n "$CLAUDE_EFFORT" ] && tag="$tag, $CLAUDE_EFFORT"
    export GIT_AUTHOR_NAME="$base | $tag"
}

# In a Cursor Agent tool shell, tag git author as "<user.name> | <model>[, <effort>]".
# The live model is read from ~/.cursor/cli-config.json; the prefix comes from git config.
setCursorGitAuthor() {
    [ -n "$CURSOR_AGENT" ] || return
    local cfg="$HOME/.cursor/cli-config.json" base model_name effort tag
    [ -f "$cfg" ] || return
    model_name=$(/usr/bin/jq -r '.model.displayNameShort // .model.displayName // .model.modelId // empty' "$cfg")
    [ -n "$model_name" ] || return
    effort=$(/usr/bin/jq -r '(.selectedModel.parameters // [])[] | select(.id=="effort") | .value // empty' "$cfg")
    base=$(command git config user.name 2>/dev/null)
    [ -n "$base" ] || return
    tag="$model_name"
    [ -n "$effort" ] && tag="$tag, $effort"
    export GIT_AUTHOR_NAME="$base | $tag"
}
setClaudeGitAuthor
setCursorGitAuthor

# Cursor/Claude tool shells restore a bashrc snapshot before injecting CURSOR_AGENT /
# CLAUDE_CODE_*; the one-shot calls above can miss those flags. Re-run on every git.
git() {
    setClaudeGitAuthor
    setCursorGitAuthor
    command git "$@"
}
