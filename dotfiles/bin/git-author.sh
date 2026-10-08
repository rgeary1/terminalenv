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
    base=$(/usr/bin/git config user.name 2>/dev/null)
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
    base=$(/usr/bin/git config user.name 2>/dev/null)
    [ -n "$base" ] || return
    tag="$model_name"
    [ -n "$effort" ] && tag="$tag, $effort"
    export GIT_AUTHOR_NAME="$base | $tag"
}

# In a Codex tool shell, tag commits with the active model and effort.
# Codex's tool commands expose a session id; its latest turn_context has the model.
setCodexGitAuthor() {
    [ -n "${CODEX_SESSION_ID:-}" ] && [ -z "${GIT_AUTHOR_NAME:-}" ] || return

    local args=("$@") git_context=() subcommand= arg i=0 base model effort tag
    while (( i < ${#args[@]} )); do
        arg=${args[i]}
        case "$arg" in
            -C|-c|--git-dir|--work-tree|--namespace|--config-env)
                (( i + 1 < ${#args[@]} )) || break
                git_context+=("$arg" "${args[i+1]}")
                (( i += 2 ))
                ;;
            -C*|-c*|--git-dir=*|--work-tree=*|--namespace=*|--config-env=*)
                git_context+=("$arg")
                (( i += 1 ))
                ;;
            -*)
                (( i += 1 ))
                ;;
            *)
                subcommand=$arg
                break
                ;;
        esac
    done
    [ "$subcommand" = commit ] || return

    base=$(/usr/bin/git "${git_context[@]}" config user.name 2>/dev/null)
    [ -n "$base" ] || return
    IFS=$'\t' read -r model effort < <(python3 - "$CODEX_SESSION_ID" <<'PY'
import json
import os
from pathlib import Path
import re
import sys

session_id = sys.argv[1]
if not re.fullmatch(r"[0-9a-f-]{36}", session_id):
    sys.exit(0)

codex_home = Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex")
paths = list((codex_home / "sessions").glob(f"*/*/*/*{session_id}.jsonl"))
if len(paths) != 1:
    sys.exit(0)

model = effort = ""
with paths[0].open(encoding="utf-8") as transcript:
    for line in transcript:
        if '"type":"turn_context"' not in line:
            continue
        payload = json.loads(line).get("payload", {})
        model = payload.get("model") or model
        effort = payload.get("effort") or effort

if model:
    if model.startswith("gpt-"):
        model = "GPT-" + model[4:].replace("-", " ").title()
    print(f"{model}\t{effort}")
PY
    )
    [ -n "$model" ] || return
    tag=$model
    [ -n "$effort" ] && tag+=", $effort"
    export GIT_AUTHOR_NAME="$base | $tag"
}
setClaudeGitAuthor
setCursorGitAuthor

# A repo can opt out of agent tagging, e.g. a public repo that must show only
# its own identity:
#   git config attribution.agentTag false
#   git config user.email <id>+<login>@users.noreply.github.com
# Then author and committer come from the repo's user.name and user.email. They
# override GIT_AUTHOR_* / GIT_COMMITTER_* from the functions above and from
# Claude Code, which exports the account email. Returns 1 if the repo did not
# opt out. Call it in a subshell: it exports into the current shell.
useRepoIdentity() {
    local args=("$@") ctx=() i=0 name email
    while (( i < ${#args[@]} )); do
        case ${args[i]} in
            -C | -c | --git-dir | --work-tree) ctx+=("${args[i]}" "${args[i+1]}"); (( i += 2 )) ;;
            -C* | -c* | --git-dir=* | --work-tree=*) ctx+=("${args[i]}"); (( i += 1 )) ;;
            -*) (( i += 1 )) ;;
            *) break ;;
        esac
    done
    [ "$(/usr/bin/git "${ctx[@]}" config --bool attribution.agentTag 2>/dev/null)" = false ] || return 1
    name=$(/usr/bin/git "${ctx[@]}" config user.name) || return 1
    email=$(/usr/bin/git "${ctx[@]}" config user.email) || return 1
    export GIT_AUTHOR_NAME="$name" GIT_AUTHOR_EMAIL="$email"
    export GIT_COMMITTER_NAME="$name" GIT_COMMITTER_EMAIL="$email"
}

# Agent tool shells can restore a bashrc snapshot before injecting agent flags.
# Re-run the author checks on every Git invocation.
git() {
    if ( useRepoIdentity "$@" ); then
        ( useRepoIdentity "$@"; command git "$@" )
        return
    fi
    setClaudeGitAuthor
    setCursorGitAuthor
    setCodexGitAuthor "$@"
    command git "$@"
}
