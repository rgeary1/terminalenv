
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

# Get files
files=()
params=()
for arg in ${not_opts[@]}; do
  if [[ "$arg" == "." ]]; then
    files+=("$arg")
    continue
  fi
  file=$(git ls-files -- "*${arg}")
  if [[ "$file" != "" && "$arg" != "." ]]; then
    files+=("$file")
  else
    params+=("$arg")
  fi
done

