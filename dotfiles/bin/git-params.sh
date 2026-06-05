GIT_ROOT=$(git rev-parse --show-toplevel)

# Get options and params
not_opts=()
opts=()
dashdash=0
for arg in "$@"; do
  if [[ $dashdash == 1 ]]; then
    not_opts+=("$arg")
  elif [[ ${arg:0:1} == "-" ]]; then
    # Everything after -- is treated as a param
    if [[ $arg == "--" ]]; then
      dashdash=1
    else
      opts+=("$arg")
    fi
  else
    not_opts+=("$arg")
  fi
done

# Test if we want to git log another repo
if [[ ${#not_opts[@]} -gt 0 ]]; then
  f=${not_opts[0]}
  if [[ -e $f ]]; then
    d=$(dirname $f)
    other_git_root=$(cd $d && git rev-parse --show-toplevel)
    rel_path=$(realpath --relative-to $other_git_root $f)
    if [[ "${rel_path:0:2}" == ".." ]]; then
      not_opts[0]=$rel_path
      cd $other_git_root
    fi
  fi
fi

# Get files, repath to git repo root
files=()
params=()
for arg in ${not_opts[@]}; do
  if [[ "$arg" == "." ]]; then
    files+=("$arg")
    continue
  fi
  file=$(git ls-files -- "*${arg}")
  [[ ${#file} == 0 ]] && file=$(git ls-files -- "${arg}")
  if [[ "$file" != "" ]]; then
    files+=("$file")
  elif [[ "$arg" =~ "/" ]]; then
    files+=("$arg")
  else
    params+=("$arg")
  fi
done

